import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../state/app_controller.dart';

class AdminPage extends StatelessWidget {
  final AppController controller;

  const AdminPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.dashboard_outlined), text: 'Resumo'),
              Tab(icon: Icon(Icons.video_settings_outlined), text: 'Vídeos'),
              Tab(icon: Icon(Icons.manage_accounts_outlined), text: 'Usuários'),
              Tab(icon: Icon(Icons.history), text: 'Auditoria'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _DashboardTab(api: controller.api),
                _AdminVideosTab(api: controller.api),
                _AdminUsuariosTab(api: controller.api),
                _AuditoriaTab(api: controller.api),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> _pedirMotivo(BuildContext context, String titulo) async {
  final controller = TextEditingController();
  final resultado = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Motivo',
          helperText: 'Mínimo de 5 caracteres',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final motivo = controller.text.trim();
            if (motivo.length >= 5) Navigator.pop(context, motivo);
          },
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
  controller.dispose();
  return resultado;
}

void _mensagem(BuildContext context, Object mensagem) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem.toString())));
}

class _DashboardTab extends StatefulWidget {
  final ApiService api;

  const _DashboardTab({required this.api});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Map<String, dynamic>? dados;
  String? erro;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() => erro = null);
    try {
      dados = await widget.api.dashboardAdmin();
    } catch (e) {
      erro = e.toString();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (erro != null) return Center(child: FilledButton(onPressed: carregar, child: Text(erro!)));
    if (dados == null) return const Center(child: CircularProgressIndicator());
    final itens = [
      ('Usuários ativos', dados!['usuariosAtivos'], Icons.people),
      ('Usuários banidos', dados!['usuariosBanidos'], Icons.person_off),
      ('Vídeos ativos', dados!['videosAtivos'], Icons.video_library),
      ('Vídeos removidos', dados!['videosRemovidos'], Icons.hide_source),
    ];
    return RefreshIndicator(
      onRefresh: carregar,
      child: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
        childAspectRatio: 1.25,
        children: [
          for (final item in itens)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.$3, size: 34),
                    const SizedBox(height: 8),
                    Text('${item.$2 ?? 0}', style: Theme.of(context).textTheme.headlineMedium),
                    Text(item.$1, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminVideosTab extends StatefulWidget {
  final ApiService api;

  const _AdminVideosTab({required this.api});

  @override
  State<_AdminVideosTab> createState() => _AdminVideosTabState();
}

class _AdminVideosTabState extends State<_AdminVideosTab> {
  final buscaController = TextEditingController();
  List<Map<String, dynamic>>? videos;
  String status = '';
  String? erro;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  Future<void> carregar() async {
    setState(() => erro = null);
    try {
      videos = await widget.api.videosAdmin(busca: buscaController.text.trim(), status: status);
    } catch (e) {
      erro = e.toString();
    }
    if (mounted) setState(() {});
  }

  Future<void> remover(Map<String, dynamic> video) async {
    final motivo = await _pedirMotivo(context, 'Remover “${video['titulo']}”?');
    if (motivo == null || !mounted) return;
    try {
      await widget.api.removerVideoAdmin((video['id'] as num).toInt(), motivo);
      await carregar();
    } catch (e) {
      if (mounted) _mensagem(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: buscaController,
                  onSubmitted: (_) => carregar(),
                  decoration: const InputDecoration(labelText: 'Título ou canal', prefixIcon: Icon(Icons.search)),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: '', child: Text('Todos')),
                  DropdownMenuItem(value: 'ATIVO', child: Text('Ativos')),
                  DropdownMenuItem(value: 'REMOVIDO', child: Text('Removidos')),
                ],
                onChanged: (valor) {
                  setState(() => status = valor ?? '');
                  carregar();
                },
              ),
              IconButton(onPressed: carregar, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: erro != null
              ? Center(child: Text(erro!))
              : videos == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: videos!.length,
                      itemBuilder: (context, index) {
                        final video = videos![index];
                        final ativo = video['status'] == 'ATIVO';
                        return ListTile(
                          leading: Icon(ativo ? Icons.movie_outlined : Icons.hide_source),
                          title: Text(video['titulo']?.toString() ?? ''),
                          subtitle: Text('@${video['canal']} • ${video['status']} • ${video['curtidas']} curtida(s)'),
                          trailing: ativo
                              ? IconButton(tooltip: 'Remover como administrador', onPressed: () => remover(video), icon: const Icon(Icons.delete_forever))
                              : null,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _AdminUsuariosTab extends StatefulWidget {
  final ApiService api;

  const _AdminUsuariosTab({required this.api});

  @override
  State<_AdminUsuariosTab> createState() => _AdminUsuariosTabState();
}

class _AdminUsuariosTabState extends State<_AdminUsuariosTab> {
  final buscaController = TextEditingController();
  List<Map<String, dynamic>>? usuarios;
  String status = '';
  String? erro;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  @override
  void dispose() {
    buscaController.dispose();
    super.dispose();
  }

  Future<void> carregar() async {
    setState(() => erro = null);
    try {
      usuarios = await widget.api.usuariosAdmin(busca: buscaController.text.trim(), status: status);
    } catch (e) {
      erro = e.toString();
    }
    if (mounted) setState(() {});
  }

  Future<void> alterarStatus(Map<String, dynamic> usuario) async {
    final banido = usuario['status'] == 'BANIDO';
    final motivo = await _pedirMotivo(context, banido ? 'Reativar usuário?' : 'Banir usuário?');
    if (motivo == null || !mounted) return;
    try {
      final id = (usuario['id'] as num).toInt();
      if (banido) {
        await widget.api.reativarUsuario(id, motivo);
      } else {
        await widget.api.banirUsuario(id, motivo);
      }
      await carregar();
    } catch (e) {
      if (mounted) _mensagem(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: buscaController,
                  onSubmitted: (_) => carregar(),
                  decoration: const InputDecoration(labelText: 'Nome ou usuário', prefixIcon: Icon(Icons.search)),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: status,
                items: const [
                  DropdownMenuItem(value: '', child: Text('Todos')),
                  DropdownMenuItem(value: 'ATIVO', child: Text('Ativos')),
                  DropdownMenuItem(value: 'BANIDO', child: Text('Banidos')),
                ],
                onChanged: (valor) {
                  setState(() => status = valor ?? '');
                  carregar();
                },
              ),
              IconButton(onPressed: carregar, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: erro != null
              ? Center(child: Text(erro!))
              : usuarios == null
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: usuarios!.length,
                      itemBuilder: (context, index) {
                        final usuario = usuarios![index];
                        final admin = usuario['perfil'] == 'ADMIN';
                        final banido = usuario['status'] == 'BANIDO';
                        return ListTile(
                          leading: CircleAvatar(child: Text((usuario['nomeUsuario']?.toString() ?? '?')[0].toUpperCase())),
                          title: Text(usuario['nome']?.toString() ?? ''),
                          subtitle: Text('@${usuario['nomeUsuario']} • ${usuario['perfil']} • ${usuario['status']}'),
                          trailing: admin
                              ? const Chip(label: Text('Administrador'))
                              : FilledButton.tonalIcon(
                                  onPressed: () => alterarStatus(usuario),
                                  icon: Icon(banido ? Icons.person_add_alt_1 : Icons.person_off),
                                  label: Text(banido ? 'Reativar' : 'Banir'),
                                ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _AuditoriaTab extends StatefulWidget {
  final ApiService api;

  const _AuditoriaTab({required this.api});

  @override
  State<_AuditoriaTab> createState() => _AuditoriaTabState();
}

class _AuditoriaTabState extends State<_AuditoriaTab> {
  List<Map<String, dynamic>>? acoes;
  String? erro;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    setState(() => erro = null);
    try {
      acoes = await widget.api.auditoria();
    } catch (e) {
      erro = e.toString();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (erro != null) return Center(child: FilledButton(onPressed: carregar, child: Text(erro!)));
    if (acoes == null) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: carregar,
      child: ListView.builder(
        itemCount: acoes!.length,
        itemBuilder: (context, index) {
          final acao = acoes![index];
          return ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: Text(acao['tipo']?.toString() ?? ''),
            subtitle: Text(
              '${acao['motivo']}\nAdmin: @${acao['administrador']} • Alvo: @${acao['usuarioAlvo'] ?? '-'}',
            ),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}
