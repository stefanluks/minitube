import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class UploadPage extends StatefulWidget {
  final ApiService api;

  const UploadPage({super.key, required this.api});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final tituloController = TextEditingController();
  final descricaoController = TextEditingController();
  String? videoPath;
  String? capaPath;
  String? videoNome;
  String? capaNome;
  bool enviando = false;

  @override
  void dispose() {
    tituloController.dispose();
    descricaoController.dispose();
    super.dispose();
  }

  Future<void> escolherVideo() async {
    final arquivo = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'webm', 'mov'],
    );

    if (arquivo == null || arquivo.path == null) return;

    setState(() {
      videoPath = arquivo.path!;
      videoNome = arquivo.name;
    });
  }

  Future<void> escolherCapa() async {
    final arquivo = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    if (arquivo == null || arquivo.path == null) return;

    setState(() {
      capaPath = arquivo.path!;
      capaNome = arquivo.name;
    });
  }

  Future<void> publicar() async {
    if (tituloController.text.trim().length < 2 || videoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o título e selecione um vídeo.')),
      );
      return;
    }

    setState(() => enviando = true);
    try {
      await widget.api.publicarVideo(
        titulo: tituloController.text.trim(),
        descricao: descricaoController.text.trim(),
        videoPath: videoPath!,
        capaPath: capaPath,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Publicar vídeo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: tituloController,
            maxLength: 160,
            decoration: const InputDecoration(labelText: 'Título'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descricaoController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Descrição (opcional)',
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: enviando ? null : escolherVideo,
            icon: const Icon(Icons.video_file),
            label: Text(videoNome ?? 'Selecionar vídeo'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: enviando ? null : escolherCapa,
            icon: const Icon(Icons.image_outlined),
            label: Text(capaNome ?? 'Selecionar capa (opcional)'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: enviando ? null : publicar,
            icon: enviando
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
            label: Text(enviando ? 'Enviando...' : 'Publicar'),
          ),
        ],
      ),
    );
  }
}
