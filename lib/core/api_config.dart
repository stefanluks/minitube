class ApiConfig {
  ApiConfig._();

  // Troque pelo IPv4 do computador que está executando a API.
  // Não use localhost quando o app estiver em outro aparelho.
  static const String baseUrl = 'http://10.77.160.181:3000/api';

  static String get serverUrl {
    if (baseUrl.endsWith('/api')) {
      return baseUrl.substring(0, baseUrl.length - 4);
    }
    return baseUrl;
  }

  static String absoluteUrl(String caminho) {
    if (caminho.startsWith('http://') || caminho.startsWith('https://')) {
      return caminho;
    }
    return '$serverUrl${caminho.startsWith('/') ? caminho : '/$caminho'}';
  }
}
