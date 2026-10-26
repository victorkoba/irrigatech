import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Use o mesmo endereço base do seu ApiService / auth_register_service.
const String _baseUrl = 'http://localhost:3000/api';
const String _loginPath = '/auth/login';
const Duration _timeout = Duration(seconds: 15);

class AuthService extends ChangeNotifier {
  String? _token;
  String? _errorMessage;
  Map<String, dynamic>? _user;

  String? get token => _token;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null;

  /// Devolve true se entrou. Em caso de falha devolve false e
  /// deixa o motivo em [errorMessage].
  Future<bool> login(String email, String password) async {
    _errorMessage = null;
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl$_loginPath'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          _token = data['token'] as String?;
          _user = data['user'] as Map<String, dynamic>?;
        }
        notifyListeners();
        return true;
      }

      if (res.statusCode == 401) {
        _errorMessage = 'E-mail ou senha incorretos.';
      } else {
        _errorMessage = 'Erro no servidor (${res.statusCode}).';
      }
    } on TimeoutException {
      _errorMessage = 'Tempo esgotado ao falar com o servidor.';
    } catch (_) {
      _errorMessage = 'Não foi possível conectar ao servidor.';
    }
    notifyListeners();
    return false;
  }

  void logout() {
    _token = null;
    _user = null;
    notifyListeners();
  }

  void clearError() {}
}