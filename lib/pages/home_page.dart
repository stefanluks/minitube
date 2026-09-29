import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'admin_page.dart';
import 'channel_page.dart';
import 'videos_page.dart';

class HomePage extends StatefulWidget {
  final AppController controller;

  const HomePage({super.key, required this.controller});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int indice = 0;

  Future<void> mostrarPerfil() async {
    try {
      final perfil = await widget.controller.api.meuPerfil();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Perfil autenticado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nome: ${perfil['nome']}'),
              Text('Canal: @${perfil['nomeUsuario']}'),
              Text('Perfil: ${perfil['perfil']}'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginas = <Widget>[
      VideosPage(controller: widget.controller),
      ChannelPage(
        controller: widget.controller,
        nomeUsuario: widget.controller.nomeUsuario,
        titulo: 'Meu canal',
      ),
      if (widget.controller.administrador) AdminPage(controller: widget.controller),
    ];
    final destinos = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library), label: 'Vídeos'),
      const NavigationDestination(icon: Icon(Icons.account_circle_outlined), selectedIcon: Icon(Icons.account_circle), label: 'Canal'),
      if (widget.controller.administrador)
        const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings), label: 'Admin'),
    ];

    if (indice >= paginas.length) indice = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MiniTube'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(child: Text('@${widget.controller.nomeUsuario}')),
          ),
          IconButton(
            tooltip: 'Consultar meu perfil na API',
            onPressed: mostrarPerfil,
            icon: const Icon(Icons.badge_outlined),
          ),
          IconButton(
            tooltip: 'Sair',
            onPressed: widget.controller.sair,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(index: indice, children: paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indice,
        onDestinationSelected: (valor) => setState(() => indice = valor),
        destinations: destinos,
      ),
    );
  }
}
