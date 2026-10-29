import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/irrigation_service.dart';
import '../auth/auth_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _submitting = false;
  bool _loadingUsers = false;
  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsersIfNeeded();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsersIfNeeded() async {
    if (!mounted) return;
    final auth = context.read<AuthService>();
    setState(() => _loadingUsers = true);
    await auth.fetchUsers();
    if (!mounted) return;
    setState(() => _loadingUsers = false);
  }

  String _roleLabel(String? role, String? email) {
    final normalizedEmail = (email ?? '').trim().toLowerCase();
    final normalizedRole = (role ?? '').trim().toUpperCase();
    if (normalizedEmail == AuthService.masterAdminEmail || normalizedRole == 'ADMIN') {
      return 'ADMIN';
    }
    return 'Operador';
  }

  Future<void> _handleAddUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _feedbackMessage = null;
      _feedbackIsError = false;
    });

    final auth = context.read<AuthService>();
    final error = await auth.createOperatorUser(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (error == null) {
      final createdName = _nameCtrl.text.trim();
      _nameCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      setState(() {
        _submitting = false;
        _feedbackIsError = false;
        _feedbackMessage = 'Usuário "$createdName" cadastrado com sucesso como Operador!';
      });
    } else {
      setState(() {
        _submitting = false;
        _feedbackIsError = true;
        _feedbackMessage = error;
      });
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Você precisará entrar novamente para usar o app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    // A próxima entrada começa no Dashboard.
    context.read<IrrigationService>().setTabIndex(0);
    // O app.dart volta para o login sozinho.
    context.read<AuthService>().logout();
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryContainer, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminUserManagementSection(AuthService authService) {
    final users = authService.registeredUsers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card de Adicionar Usuário (Nome, E-mail e Senha)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant, width: 1),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: AppColors.primaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Adicionar Novo Usuário',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Exclusivo ADMIN (Master): novos usuários recebem a permissão de Operador.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_feedbackMessage != null) ...[
                  if (_feedbackIsError)
                    AuthErrorBanner(message: _feedbackMessage!)
                  else
                    AuthSuccessBanner(message: _feedbackMessage!),
                  const SizedBox(height: 14),
                ],
                AuthTextField(
                  controller: _nameCtrl,
                  label: 'Nome',
                  icon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome do usuário' : null,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _emailCtrl,
                  label: 'E-mail',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    final err = validateEmail(v);
                    if (err != null) return err;
                    if (v!.trim().toLowerCase() == AuthService.masterAdminEmail) {
                      return 'O e-mail ADMIN Master já pertence ao administrador único.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _passwordCtrl,
                  label: 'Senha',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleAddUser(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a senha';
                    if (v.length < 6) return 'A senha precisa ter pelo menos 6 caracteres';
                    return null;
                  },
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 16),
                AuthPrimaryButton(
                  label: 'Adicionar Usuário',
                  loading: _submitting,
                  onPressed: _handleAddUser,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Lista de usuários do banco separados por permissão (ADMIN e Operador)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Usuários e Permissões no Banco',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atualizar lista',
                    onPressed: _loadingUsers ? null : _loadUsersIfNeeded,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.primaryContainer,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Permissões separadas entre ADMIN (apenas 1 Master: victor@gmail.com) e Operador.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              if (_loadingUsers && users.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (users.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Nenhum usuário retornado pelo servidor no momento.',
                    style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                  ),
                )
              else
                ...users.map((u) {
                  final uName = (u['name'] as String?) ?? 'Usuário';
                  final uEmail = (u['email'] as String?) ?? '—';
                  final uRole = _roleLabel(u['role'] as String?, uEmail);
                  final isUserAdmin = uRole == 'ADMIN';

                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUserAdmin
                            ? AppColors.primaryContainer.withValues(alpha: 0.4)
                            : AppColors.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isUserAdmin
                              ? Icons.admin_panel_settings_rounded
                              : Icons.engineering_outlined,
                          color: AppColors.primaryContainer,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                uName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                uEmail,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUserAdmin
                                ? AppColors.primaryContainer
                                : AppColors.primaryContainer.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            uRole,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isUserAdmin
                                  ? AppColors.onPrimary
                                  : AppColors.primaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.user;
    final name = (user?['name'] as String?) ?? 'Usuário';
    final email = (user?['email'] as String?) ?? '—';
    final role = _roleLabel(user?['role'] as String?, email);
    final isAdmin = role == 'ADMIN';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.agriculture_rounded, color: AppColors.primaryContainer, size: 28),
            SizedBox(width: 10),
            Text(
              'Perfil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryContainer,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho do usuário
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dados da conta
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.person_outline_rounded, 'Nome', name),
                  const Divider(height: 1, color: AppColors.outlineVariant),
                  _infoRow(Icons.email_outlined, 'E-mail', email),
                  const Divider(height: 1, color: AppColors.outlineVariant),
                  _infoRow(Icons.badge_outlined, 'Função', role),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Se for ADMIN (victor@gmail.com), exibe o gerenciamento e cadastro de usuários (Operadores)
            if (isAdmin)
              _buildAdminUserManagementSection(authService)
            else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant, width: 1),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.primaryContainer,
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sua conta possui permissão de Operador. Apenas o usuário ADMIN Master (victor@gmail.com) pode cadastrar novos usuários.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Logout
            OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sair da conta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
