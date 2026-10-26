import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'auth_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  /// Mensagem verde vinda da tela de cadastro ("Cadastro realizado!...").
  final String? initialMessage;

  const LoginScreen({super.key, this.initialMessage});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _message = widget.initialMessage;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    auth.clearError();

    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });

    // AuthService.login devolve true/false e guarda a falha em errorMessage.
    final ok = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;

    if (ok) {
  // O app.dart troca para o app completo sozinho (via AuthService).
      return;
    }

    setState(() {
      _loading = false;
      _error = auth.errorMessage ?? 'Não foi possível entrar. Verifique e-mail e senha.';
    });
  }

  Future<void> _openRegister() async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (!mounted || message == null) return;
    setState(() {
      _message = message;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthBrandHeader(
                      title: 'Acesso ao sistema',
                      subtitle: 'Entre para monitorar sua irrigação',
                    ),
                    const SizedBox(height: 24),
                    AuthCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_message != null) ...[
                            AuthSuccessBanner(message: _message!),
                            const SizedBox(height: 16),
                          ],
                          if (_error != null) ...[
                            AuthErrorBanner(message: _error!),
                            const SizedBox(height: 16),
                          ],
                          AuthTextField(
                            controller: _emailCtrl,
                            label: 'E-mail',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: validateEmail,
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(
                            controller: _passwordCtrl,
                            label: 'Senha',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Informe sua senha' : null,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppColors.onSurfaceVariant,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AuthPrimaryButton(label: 'Entrar', loading: _loading, onPressed: _submit),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Não tem uma conta?',
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed: _loading ? null : _openRegister,
                          child: const Text(
                            'Cadastre-se',
                            style: TextStyle(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
