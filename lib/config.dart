import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Lê as configurações do arquivo .env (carregado no main.dart antes
/// de qualquer outra coisa). Nunca comite o .env real - apenas o
/// .env.example com os nomes das variáveis, sem os valores.
class AppConfig {
  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');
  static String get backendBaseUrl => _require('BACKEND_BASE_URL');

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception(
        'Variável "$key" não encontrada no .env. '
        'Copie .env.example para .env e preencha os valores.',
      );
    }
    return value;
  }
}
