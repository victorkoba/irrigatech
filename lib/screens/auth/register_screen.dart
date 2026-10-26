import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_register_service.dart';
import 'auth_widgets.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await registerUser(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (!mounted) return;

    if (!result.ok) {
      setState(() {
        _loading = false;
        _error = result.error ?? 'Não foi possível concluir o cadastro.';
      });
      return;
    }

    // Cadastro ok: volta para o login com o aviso verde.
    Navigator.pop(
      context,
      'Cadastro realizado! Entre com seu e-mail e senha.',
    );
  }

  void _backToLogin() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
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
                      title: 'Criar conta',
                      subtitle: 'Preencha seus dados para acessar o sistema',
                    ),
                    const SizedBox(height: 24),
                    AuthCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            AuthErrorBanner(message: _error!),
                            const SizedBox(height: 16),
                          ],
                          AuthTextField(
                            controller: _nameCtrl,
                            label: 'Nome completo',
                            icon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: validateName,
                          ),
                          const SizedBox(height: 14),
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
                            textInputAction: TextInputAction.next,
                            validator: validatePassword,
                            suffix: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppColors.onSurfaceVariant,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AuthTextField(
                            controller: _confirmCtrl,
                            label: 'Confirmar senha',
                            icon: Icons.lock_reset_rounded,
                            obscure: _obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            validator: (v) => validateConfirm(v, _passwordCtrl.text),
                          ),
                          const SizedBox(height: 20),
                          AuthPrimaryButton(
                            label: 'Criar conta',
                            loading: _loading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Já tem uma conta?',
                          style: TextStyle(color: AppColors.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed: _loading ? null : _backToLogin,
                          child: const Text(
                            'Entrar',
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
