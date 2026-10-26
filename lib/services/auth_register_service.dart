import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── AJUSTE ──────────────────────────────────────────────────────────────────
// 1) kApiBaseUrl: use exatamente o mesmo endereço base do seu ApiService
//    (o mesmo que o login já usa).
//      Android emulador → http://10.0.2.2:3000/api
//      Aparelho real    → http://IP-DO-SEU-PC:3000/api
// 2) kRegisterPath: confirme no backend o caminho do cadastro.
//      GET /api/auth/login  →  geralmente POST /api/auth/register
// Se o seu ApiService já tiver um método register, apague este arquivo e chame
// ApiService.register(...) direto na tela de cadastro.
const String _baseUrl = 'http://localhost:3000/api';
const String kRegisterPath = '/auth/register';
const Duration kRegisterTimeout = Duration(seconds: 15);
// ─────────────────────────────────────────────────────────────────────────────

class AuthRegisterResult {
  final bool ok;
  final String? error;

  const AuthRegisterResult({required this.ok, this.error});
  const AuthRegisterResult.success() : ok = true, error = null;
  const AuthRegisterResult.failure(this.error) : ok = false;
}

/// Cria um usuário novo no backend (tabela users: name, email, password_hash,
/// role). O papel é definido pelo servidor — no schema.sql o padrão é
/// 'operator', então o cadastro entra como operador.
Future<AuthRegisterResult> registerUser({
  required String name,
  required String email,
  required String password,
}) async {
  try {
    final res = await http
        .post(
          Uri.parse('$_baseUrl$kRegisterPath'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
          }),
        )
        .timeout(kRegisterTimeout);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return const AuthRegisterResult.success();
    }

    final serverMessage = _messageFrom(res.body);

    if (res.statusCode == 409) {
      return const AuthRegisterResult.failure('Este e-mail já está cadastrado.');
    }
    if (res.statusCode == 400 || res.statusCode == 422) {
      return AuthRegisterResult.failure(
        serverMessage ?? 'Confira os dados: nome, e-mail e senha.',
      );
    }
    return AuthRegisterResult.failure(
      serverMessage ?? 'O servidor não pôde concluir o cadastro (erro ${res.statusCode}).',
    );
  } on TimeoutException {
    return const AuthRegisterResult.failure('Tempo esgotado ao falar com o servidor.');
  } catch (_) {
    return const AuthRegisterResult.failure(
      'Não foi possível conectar ao servidor. Verifique sua conexão.',
    );
  }
}

String? _messageFrom(String body) {
  try {
    final data = jsonDecode(body);
    if (data is Map<String, dynamic>) {
      final raw = data['error'] ?? data['message'];
      if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    }
  } catch (_) {
    // corpo não é JSON — usa a mensagem padrão
  }
  return null;
}
