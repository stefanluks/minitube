import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class AppController extends ChangeNotifier {
  final ApiService api = ApiService();

  Map<String, dynamic>? usuario;
  bool carregando = false;

  bool get autenticado => usuario != null && api.token != null;
  bool get administrador => usuario?['perfil'] == 'ADMIN';
  String get nomeUsuario => usuario?['nomeUsuario']?.toString() ?? '';

  Future<void> entrar(String nomeUsuario, String senha) async {
    carregando = true;
    notifyListeners();
    try {
      usuario = await api.login(nomeUsuario, senha);
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  void sair() {
    api.token = null;
    usuario = null;
    notifyListeners();
  }
}
