import 'package:flutter/material.dart';

import '../core/api_config.dart';
import '../state/app_controller.dart';

class AuthPage extends StatefulWidget {
  final AppController controller;

  const AuthPage({super.key, required this.controller});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final nomeController = TextEditingController();
  final usuarioController = TextEditingController();
  final senhaController = TextEditingController();
  bool cadastro = false;
  bool ocultarSenha = true;
  bool enviando = false;

  @override
  void dispose() {
    nomeController.dispose();
    usuarioController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  void mensagem(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: erro ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> enviar() async {
    if (usuarioController.text.trim().isEmpty || senhaController.text.isEmpty) {
      mensagem('Preencha o usuário e a senha.', erro: true);
      return;
    }
    if (cadastro && nomeController.text.trim().isEmpty) {
      mensagem('Preencha o nome completo.', erro: true);
      return;
    }

    setState(() => enviando = true);
    try {
      if (cadastro) {
        await widget.controller.api.cadastrar(
          nome: nomeController.text.trim(),
          nomeUsuario: usuarioController.text.trim(),
          senha: senhaController.text,
        );
        if (!mounted) return;
        mensagem('Conta criada. Agora faça o login.');
        setState(() => cadastro = false);
      } else {
        await widget.controller.entrar(
          usuarioController.text.trim(),
          senhaController.text,
        );
      }
    } catch (error) {
      if (mounted) mensagem(error.toString(), erro: true);
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  Future<void> testarApi() async {
    try {
      mensagem(await widget.controller.api.health());
    } catch (error) {
      mensagem('$error\nConfira o IP em ${ApiConfig.baseUrl}', erro: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.ondemand_video, size: 64, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        'MiniTube',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cadastro ? 'Crie uma conta de aluno' : 'Entre para testar a API',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (cadastro) ...[
                        TextField(
                          controller: nomeController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Nome completo'),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: usuarioController,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        decoration: const InputDecoration(labelText: 'Nome de usuário'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: senhaController,
                        obscureText: ocultarSenha,
                        onSubmitted: (_) => enviar(),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => ocultarSenha = !ocultarSenha),
                            icon: Icon(ocultarSenha ? Icons.visibility : Icons.visibility_off),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: enviando ? null : enviar,
                        icon: enviando
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(cadastro ? Icons.person_add : Icons.login),
                        label: Text(cadastro ? 'Cadastrar' : 'Entrar'),
                      ),
                      TextButton(
                        onPressed: enviando ? null : () => setState(() => cadastro = !cadastro),
                        child: Text(cadastro ? 'Já tenho conta' : 'Criar uma conta'),
                      ),
                      const Divider(),
                      OutlinedButton.icon(
                        onPressed: testarApi,
                        icon: const Icon(Icons.lan),
                        label: const Text('Testar conexão com a API'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
