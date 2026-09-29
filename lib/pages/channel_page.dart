import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'player_page.dart';

class ChannelPage extends StatefulWidget {
  final AppController controller;
  final String nomeUsuario;
  final String titulo;

  const ChannelPage({
    super.key,
    required this.controller,
    required this.nomeUsuario,
    this.titulo = 'Canal',
  });

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage> {
  bool carregando = true;
  String? erro;
  Map<String, dynamic>? dados;

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
      dados = await widget.controller.api.canal(widget.nomeUsuario);
    } catch (e) {
      erro = e.toString();
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dentroDaNavegacao = widget.titulo == 'Meu canal';
    final conteudo = _conteudo();
    if (dentroDaNavegacao) return conteudo;
    return Scaffold(appBar: AppBar(title: Text(widget.titulo)), body: conteudo);
  }

  Widget _conteudo() {
    if (carregando) return const Center(child: CircularProgressIndicator());
    if (erro != null) {
      return Center(child: FilledButton.icon(onPressed: carregar, icon: const Icon(Icons.refresh), label: Text(erro!)));
    }
    final canal = Map<String, dynamic>.from(dados?['canal'] as Map? ?? {});
    final videos = (dados?['videos'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return RefreshIndicator(
      onRefresh: carregar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 42, child: Icon(Icons.person, size: 48)),
          const SizedBox(height: 10),
          Text(canal['nome']?.toString() ?? '', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          Text('@${canal['nomeUsuario'] ?? widget.nomeUsuario}', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text('Vídeos (${videos.length})', style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          if (videos.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Este canal não possui vídeos.'))),
          for (final video in videos)
            Card(
              child: ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(video['titulo']?.toString() ?? ''),
                subtitle: Text('${video['curtidas'] ?? 0} curtida(s)'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlayerPage(api: widget.controller.api, video: video)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
