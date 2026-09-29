import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/api_config.dart';
import '../services/api_service.dart';

class PlayerPage extends StatefulWidget {
  final ApiService api;
  final Map<String, dynamic> video;

  const PlayerPage({super.key, required this.api, required this.video});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final VideoPlayerController controller;
  late final Future<void> inicializacao;

  @override
  void initState() {
    super.initState();
    final url = ApiConfig.absoluteUrl(widget.video['streamUrl'].toString());
    controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: widget.api.authHeaders,
    );
    inicializacao = controller.initialize().then((_) => controller.play());
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.video['titulo']?.toString() ?? 'Vídeo')),
      body: Center(
        child: FutureBuilder<void>(
          future: inicializacao,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Não foi possível abrir o vídeo.\n${snapshot.error}', textAlign: TextAlign.center),
              );
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
                VideoProgressIndicator(controller, allowScrubbing: true, padding: const EdgeInsets.all(16)),
                IconButton.filled(
                  onPressed: () {
                    setState(() {
                      controller.value.isPlaying ? controller.pause() : controller.play();
                    });
                  },
                  icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
