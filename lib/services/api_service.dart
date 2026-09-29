import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../core/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  String? token;

  Map<String, String> get authHeaders => {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<String> health() async {
    final response = await http.get(Uri.parse('${ApiConfig.serverUrl}/health'));
    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300 || json['sucesso'] != true) {
      throw ApiException(
        json['mensagem']?.toString() ?? 'A API não está disponível.',
        response.statusCode,
      );
    }
    return json['mensagem']?.toString() ?? 'API respondeu.';
  }

  Future<Map<String, dynamic>> cadastrar({
    required String nome,
    required String nomeUsuario,
    required String senha,
  }) async {
    return _map(await _request(
      'POST',
      '/auth/cadastro',
      body: {'nome': nome, 'nomeUsuario': nomeUsuario, 'senha': senha},
    ));
  }

  Future<Map<String, dynamic>> login(String nomeUsuario, String senha) async {
    final dados = _map(await _request(
      'POST',
      '/auth/login',
      body: {'nomeUsuario': nomeUsuario, 'senha': senha},
    ));
    token = dados['token']?.toString();
    return _map(dados['usuario']);
  }

  Future<Map<String, dynamic>> meuPerfil() async {
    return _map(await _request('GET', '/auth/me'));
  }

  Future<List<Map<String, dynamic>>> listarVideos() async {
    final dados = _map(await _request('GET', '/videos'));
    return _list(dados['videos']);
  }

  Future<Map<String, dynamic>> detalhesVideo(int id) async {
    return _map(await _request('GET', '/videos/$id'));
  }

  Future<Map<String, dynamic>> publicarVideo({
    required String titulo,
    required String descricao,
    required String videoPath,
    String? capaPath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/videos'),
    );
    request.headers.addAll(authHeaders);
    request.fields['titulo'] = titulo;
    request.fields['descricao'] = descricao;
    request.files.add(await http.MultipartFile.fromPath(
      'video',
      videoPath,
      contentType: _contentType(videoPath, video: true),
    ));
    if (capaPath != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'capa',
        capaPath,
        contentType: _contentType(capaPath, video: false),
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _map(_extractData(response));
  }

  Future<void> removerMeuVideo(int id) async {
    await _request('DELETE', '/videos/$id');
  }

  Future<Map<String, dynamic>> curtir(int id) async {
    return _map(await _request('POST', '/videos/$id/curtidas'));
  }

  Future<Map<String, dynamic>> descurtir(int id) async {
    return _map(await _request('DELETE', '/videos/$id/curtidas'));
  }

  Future<Map<String, dynamic>> canal(String nomeUsuario) async {
    final nome = Uri.encodeComponent(nomeUsuario);
    return _map(await _request('GET', '/usuarios/$nome/canal'));
  }

  Future<Map<String, dynamic>> dashboardAdmin() async {
    return _map(await _request('GET', '/admin/dashboard'));
  }

  Future<List<Map<String, dynamic>>> videosAdmin({
    String busca = '',
    String status = '',
  }) async {
    final query = Uri(queryParameters: {
      if (busca.isNotEmpty) 'busca': busca,
      if (status.isNotEmpty) 'status': status,
    }).query;
    return _list(await _request('GET', '/admin/videos${query.isEmpty ? '' : '?$query'}'));
  }

  Future<void> removerVideoAdmin(int id, String motivo) async {
    await _request('DELETE', '/admin/videos/$id', body: {'motivo': motivo});
  }

  Future<List<Map<String, dynamic>>> usuariosAdmin({
    String busca = '',
    String status = '',
  }) async {
    final query = Uri(queryParameters: {
      if (busca.isNotEmpty) 'busca': busca,
      if (status.isNotEmpty) 'status': status,
    }).query;
    return _list(await _request('GET', '/admin/usuarios${query.isEmpty ? '' : '?$query'}'));
  }

  Future<void> banirUsuario(int id, String motivo) async {
    await _request('PATCH', '/admin/usuarios/$id/banir', body: {'motivo': motivo});
  }

  Future<void> reativarUsuario(int id, String motivo) async {
    await _request('PATCH', '/admin/usuarios/$id/reativar', body: {'motivo': motivo});
  }

  Future<List<Map<String, dynamic>>> auditoria() async {
    return _list(await _request('GET', '/admin/auditoria'));
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = {
      ...authHeaders,
      if (body != null) 'Content-Type': 'application/json',
    };
    final encoded = body == null ? null : jsonEncode(body);

    late http.Response response;
    switch (method) {
      case 'POST':
        response = await http.post(uri, headers: headers, body: encoded);
        break;
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: encoded);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers, body: encoded);
        break;
      default:
        response = await http.get(uri, headers: headers);
    }
    return _extractData(response);
  }

  dynamic _extractData(http.Response response) {
    final json = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300 || json['sucesso'] != true) {
      throw ApiException(
        json['mensagem']?.toString() ?? 'Falha na comunicação com a API.',
        response.statusCode,
      );
    }
    return json['dados'];
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      throw ApiException('A API retornou uma resposta inválida.', response.statusCode);
    }
    throw ApiException('A API retornou uma resposta inválida.', response.statusCode);
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const ApiException('Formato de dados inesperado.');
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) throw const ApiException('Formato de lista inesperado.');
    return value.map((item) => _map(item)).toList();
  }

  MediaType _contentType(String path, {required bool video}) {
    final extensao = path.split('.').last.toLowerCase();
    if (video) {
      return MediaType('video', extensao == 'mov' ? 'quicktime' : extensao);
    }
    return MediaType('image', extensao == 'jpg' ? 'jpeg' : extensao);
  }
}
