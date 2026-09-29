import 'package:flutter/material.dart';

import '../core/api_config.dart';
import '../state/app_controller.dart';
import 'channel_page.dart';
import 'player_page.dart';
import 'upload_page.dart';

class VideosPage extends StatefulWidget {
  final AppController controller;

  const VideosPage({super.key, required this.controller});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  bool carregando = true;
  String? erro;
  List<Map<String, dynamic>> videos = [];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() {
      carregando = true;
      erro = null;
    });
    try {
      videos = await widget.controller.api.listarVideos();
    } catch (e) {
      erro = e.toString();
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  Future<void> alternarCurtida(Map<String, dynamic> video) async {
    try {
      final id = (video['id'] as num).toInt();
      final curtido = video['curtidoPorMim'] == true;
      final dados = curtido
          ? await widget.controller.api.descurtir(id)
          : await widget.controller.api.curtir(id);
      setState(() {
        video['curtidoPorMim'] = dados['curtido'];
        video['curtidas'] = dados['total'];
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> remover(Map<String, dynamic> video) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover vídeo?'),
        content: Text('O vídeo “${video['titulo']}” deixará de aparecer no canal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
        ],
      ),
    );
    if (confirmou != true) return;
    try {
      await widget.controller.api.removerMeuVideo((video['id'] as num).toInt());
      await carregar();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> abrirUpload() async {
    final publicou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => UploadPage(api: widget.controller.api)),
    );
    if (publicou == true) carregar();
  }

  Future<void> abrirVideo(Map<String, dynamic> video) async {
    try {
      final detalhes = await widget.controller.api.detalhesVideo((video['id'] as num).toInt());
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerPage(api: widget.controller.api, video: detalhes)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) return const Center(child: CircularProgressIndicator());
    if (erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(erro!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: carregar, icon: const Icon(Icons.refresh), label: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: carregar,
        child: videos.isEmpty
            ? ListView(children: const [SizedBox(height: 180), Center(child: Text('Nenhum vídeo publicado.'))])
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  final meuVideo = video['canal'] == widget.controller.nomeUsuario;
                  final capa = video['capaUrl']?.toString();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: () => abrirVideo(video),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: capa == null
                                ? const ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.play_circle, size: 64))
                                : Image.network(
                                    ApiConfig.absoluteUrl(capa),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const ColoredBox(
                                      color: Color(0xFFE0E0E0),
                                      child: Icon(Icons.broken_image_outlined, size: 48),
                                    ),
                                  ),
                          ),
                        ),
                        ListTile(
                          title: Text(video['titulo']?.toString() ?? ''),
                          subtitle: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChannelPage(
                                  controller: widget.controller,
                                  nomeUsuario: video['canal'].toString(),
                                ),
                              ),
                            ),
                            child: Text('@${video['canal']}'),
                          ),
                          trailing: meuVideo
                              ? IconButton(tooltip: 'Remover meu vídeo', onPressed: () => remover(video), icon: const Icon(Icons.delete_outline))
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: video['curtidoPorMim'] == true ? 'Descurtir' : 'Curtir',
                                onPressed: () => alternarCurtida(video),
                                icon: Icon(video['curtidoPorMim'] == true ? Icons.thumb_up : Icons.thumb_up_outlined),
                              ),
                              Text('${video['curtidas'] ?? 0}'),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => abrirVideo(video),
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Assistir'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: abrirUpload,
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
    );
  }
}
