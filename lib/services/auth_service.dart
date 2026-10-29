import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Use o mesmo endereço base do seu ApiService / auth_register_service.
const String _baseUrl = 'http://localhost:3000/api';
const String _loginPath = '/auth/login';
const String _registerPath = '/auth/register';
const String _usersPath = '/auth/users';
const Duration _timeout = Duration(seconds: 15);

class AuthService extends ChangeNotifier {
  static const String masterAdminEmail = 'victor@gmail.com';

  String? _token;
  String? _errorMessage;
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _registeredUsers = [];

  String? get token => _token;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null;
  List<Map<String, dynamic>> get registeredUsers => List.unmodifiable(_registeredUsers);

  bool get isAdmin {
    final email = (_user?['email'] as String?)?.trim().toLowerCase() ?? '';
    final role = (_user?['role'] as String?)?.trim().toUpperCase() ?? '';
    return email == masterAdminEmail || role == 'ADMIN';
  }

  String get roleDisplay => isAdmin ? 'ADMIN' : 'Operador';

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
          final rawUser = data['user'] as Map<String, dynamic>?;
          if (rawUser != null) {
            final normalizedEmail = (rawUser['email'] as String?)?.trim().toLowerCase() ?? '';
            rawUser['role'] = normalizedEmail == masterAdminEmail ? 'ADMIN' : 'Operador';
            _user = rawUser;
          }
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

  /// Lista todos os usuários cadastrados no banco de dados (separados entre ADMIN e Operador).
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl$_usersPath'),
            headers: const {'Content-Type': 'application/json'},
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic> && data['users'] is List) {
          _registeredUsers = (data['users'] as List)
              .whereType<Map>()
              .map((u) => Map<String, dynamic>.from(u))
              .toList();
          notifyListeners();
          return _registeredUsers;
        }
      }
    } catch (_) {
      // Fallback silencioso caso o backend esteja offline
    }
    return _registeredUsers;
  }

  /// Cadastra um novo usuário Operador no banco de dados (ação exclusiva do ADMIN na tela de Perfil).
  /// Retorna `null` em caso de sucesso ou a mensagem de erro em caso de falha.
  Future<String?> createOperatorUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl$_registerPath'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(_timeout);

      if (res.statusCode == 201) {
        await fetchUsers();
        return null;
      }

      try {
        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic> && data['error'] is String) {
          return data['error'] as String;
        }
      } catch (_) {}
      return 'Erro ao cadastrar usuário (${res.statusCode}).';
    } on TimeoutException {
      return 'Tempo esgotado ao falar com o servidor.';
    } catch (_) {
      return 'Não foi possível conectar ao servidor.';
    }
  }

  void logout() {
    _token = null;
    _user = null;
    _registeredUsers = [];
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }

  @visibleForTesting
  void setTestUser(Map<String, dynamic>? user, {String? token = 'test-jwt'}) {
    _user = user;
    _token = user != null ? token : null;
    notifyListeners();
  }
}
