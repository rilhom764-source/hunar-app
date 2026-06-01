import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../l10n/localization_provider.dart';
import '../providers/app_state_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  // Phone auth controllers
  final _phoneCtrl = TextEditingController();
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());
  bool _isCodeStep = false;

  // Email auth controllers
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isEmailLogin = true; // true = login, false = register
  bool _obscurePassword = true;

  // Auth method: 'phone' or 'email'
  String _authMethod = 'phone';

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final n in _codeFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _fullCode => _codeControllers.map((c) => c.text).join();

  void _clearCode() {
    for (final c in _codeControllers) {
      c.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.watch<LocalizationProvider>();
    final state = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildLogo(),
                  const SizedBox(height: 14),
                  const Text(
                    'Hunar',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepSlate,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.tr('auth_welcome_subtitle'),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.slateGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Auth method switcher
                  _buildAuthMethodSwitcher(l10n),

                  const SizedBox(height: 20),

                  if (state.authError != null)
                    _buildErrorBanner(_translateError(state.authError!, l10n)),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.15, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _authMethod == 'phone'
                        ? (_isCodeStep
                            ? _buildCodeStep(l10n, state)
                            : _buildPhoneStep(l10n, state))
                        : _buildEmailStep(l10n, state),
                  ),

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      l10n.tr('auth_terms'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.lightSlate,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // AUTH METHOD SWITCHER
  // ═══════════════════════════════════════════════
  Widget _buildAuthMethodSwitcher(LocalizationProvider l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _authMethod = 'phone'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _authMethod == 'phone' ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _authMethod == 'phone'
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_android_rounded,
                      size: 22,
                      color: _authMethod == 'phone' ? Colors.white : AppColors.slateGray,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Телефон',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _authMethod == 'phone' ? Colors.white : AppColors.slateGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _authMethod = 'email'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _authMethod == 'email' ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _authMethod == 'email'
                      ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_rounded,
                      size: 22,
                      color: _authMethod == 'email' ? Colors.white : AppColors.slateGray,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _authMethod == 'email' ? Colors.white : AppColors.slateGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // EMAIL AUTH STEP
  // ═══════════════════════════════════════════════
  Widget _buildEmailStep(LocalizationProvider l10n, AppStateProvider state) {
    return Column(
      key: ValueKey('email_step_${_isEmailLogin ? 'login' : 'register'}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          icon: _isEmailLogin ? Icons.login_rounded : Icons.person_add_rounded,
          color: _isEmailLogin ? AppColors.primary : AppColors.info,
          title: _isEmailLogin ? 'Вход по email' : 'Регистрация',
          subtitle: _isEmailLogin
              ? 'Введите email и пароль для входа'
              : 'Создайте аккаунт с email и паролем',
        ),
        const SizedBox(height: 20),

        // Name field (only for registration)
        if (!_isEmailLogin) ...[
          _buildTextField(
            controller: _nameCtrl,
            icon: Icons.person_outline_rounded,
            hint: 'Ваше имя',
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
        ],

        // Email field
        _buildTextField(
          controller: _emailCtrl,
          icon: Icons.email_outlined,
          hint: 'Email адрес',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),

        // Password field
        _buildTextField(
          controller: _passwordCtrl,
          icon: Icons.lock_outline_rounded,
          hint: 'Пароль',
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: AppColors.lightSlate,
              size: 22,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),

        const SizedBox(height: 24),

        // Login / Register button
        _buildPrimaryButton(
          isLoading: state.isAuthLoading,
          label: _isEmailLogin ? 'Войти' : 'Зарегистрироваться',
          icon: _isEmailLogin ? Icons.login_rounded : Icons.person_add_rounded,
          onPressed: _isEmailLogin ? _handleEmailLogin : _handleEmailRegister,
        ),

        const SizedBox(height: 16),

        // Toggle login/register
        Center(
          child: GestureDetector(
            onTap: () => setState(() => _isEmailLogin = !_isEmailLogin),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: AppColors.slateGray),
                children: [
                  TextSpan(
                    text: _isEmailLogin ? 'Нет аккаунта? ' : 'Уже есть аккаунт? ',
                  ),
                  TextSpan(
                    text: _isEmailLogin ? 'Зарегистрироваться' : 'Войти',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.background,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.deepSlate,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 15,
            color: AppColors.lightSlate.withValues(alpha: 0.7),
          ),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 24),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // PHONE AUTH STEPS (existing)
  // ═══════════════════════════════════════════════
  Widget _buildPhoneStep(LocalizationProvider l10n, AppStateProvider state) {
    return Column(
      key: const ValueKey('phone_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          icon: Icons.sms_rounded,
          color: AppColors.primary,
          title: l10n.tr('auth_phone_label'),
          subtitle: l10n.tr('auth_phone_step_desc'),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.background,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('\u{1f1f9}\u{1f1ef}', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 6),
                    Text(
                      '+992',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepSlate,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 30,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
              Expanded(
                child: TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepSlate,
                    letterSpacing: 1.5,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  decoration: InputDecoration(
                    hintText: '900 000 000',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: AppColors.lightSlate.withValues(alpha: 0.5),
                      letterSpacing: 1,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tr('auth_phone_format_hint'),
          style: const TextStyle(fontSize: 12, color: AppColors.lightSlate),
        ),
        const SizedBox(height: 24),
        _buildPrimaryButton(
          isLoading: state.isAuthLoading,
          label: l10n.tr('auth_send_code'),
          icon: Icons.sms_rounded,
          onPressed: _handleSendCode,
        ),
      ],
    );
  }

  Widget _buildCodeStep(LocalizationProvider l10n, AppStateProvider state) {
    return Column(
      key: const ValueKey('code_step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          icon: Icons.mark_chat_read_rounded,
          color: AppColors.success,
          title: l10n.tr('auth_code_sent'),
          subtitle: _formatTajikPhoneForDisplay(_phoneCtrl.text.trim()),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            l10n.tr('auth_code_label'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.deepSlate,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            return Container(
              width: 46,
              height: 54,
              margin: EdgeInsets.only(
                left: i > 0 ? 7 : 0,
                right: i == 2 ? 7 : 0,
              ),
              child: TextField(
                controller: _codeControllers[i],
                focusNode: _codeFocusNodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepSlate,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: _codeControllers[i].text.isNotEmpty
                      ? AppColors.primary.withValues(alpha: 0.06)
                      : AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (val) {
                  setState(() {});
                  if (val.isNotEmpty && i < 5) {
                    _codeFocusNodes[i + 1].requestFocus();
                  }
                  if (val.isEmpty && i > 0) {
                    _codeFocusNodes[i - 1].requestFocus();
                  }
                  if (_fullCode.length == 6) {
                    _handleVerifyCode();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        _buildPrimaryButton(
          isLoading: state.isAuthLoading,
          label: l10n.tr('auth_verify'),
          icon: Icons.verified_user_rounded,
          onPressed: _handleVerifyCode,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () {
                _clearCode();
                _handleSendCode();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                l10n.tr('auth_resend_code'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => setState(() {
                _isCodeStep = false;
                _clearCode();
              }),
              icon: const Icon(Icons.phone_rounded, size: 18),
              label: Text(
                l10n.tr('auth_change_phone'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════
  Widget _buildLogo() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Image.asset(
          'assets/icon/app_icon.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Text(
              'H',
              style: TextStyle(
                color: Colors.white,
                fontSize: 46,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.deepSlate,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: color == AppColors.success
                        ? AppColors.primary
                        : AppColors.slateGray,
                    fontWeight: color == AppColors.success
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(fontSize: 14, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required bool isLoading,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // HANDLERS
  // ═══════════════════════════════════════════════
  void _handleEmailLogin() {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || !email.contains('@')) {
      _showError('Введите корректный email');
      return;
    }
    if (password.length < 6) {
      _showError('Пароль должен быть не менее 6 символов');
      return;
    }

    context.read<AppStateProvider>().signInWithEmail(
      email: email,
      password: password,
      onError: (err) => _showError(err),
    );
  }

  void _handleEmailRegister() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty) {
      _showError('Введите ваше имя');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showError('Введите корректный email');
      return;
    }
    if (password.length < 6) {
      _showError('Пароль должен быть не менее 6 символов');
      return;
    }

    context.read<AppStateProvider>().registerWithEmail(
      email: email,
      password: password,
      fullName: name,
      onError: (err) => _showError(err),
    );
  }

  String _translateError(String error, LocalizationProvider l10n) {
    if (error.contains('BILLING_NOT_ENABLED') || error.contains('billing')) {
      return l10n.tr('auth_error_billing');
    }
    if (error.contains('INVALID_PHONE') ||
        error.contains('invalid-phone-number')) {
      return l10n.tr('auth_phone_invalid');
    }
    if (error.contains('TOO_MANY_REQUESTS') ||
        error.contains('too-many-requests')) {
      return l10n.tr('auth_error_too_many');
    }
    if (error.contains('QUOTA_EXCEEDED')) {
      return l10n.tr('auth_error_quota');
    }
    if (error.contains('NETWORK_ERROR') || error.contains('network')) {
      return l10n.tr('auth_error_network');
    }
    if (error.contains('APP_NOT_AUTHORIZED')) {
      return l10n.tr('auth_error_app_not_auth');
    }
    return error;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _normalizeTajikPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('992') && digits.length > 9) {
      digits = digits.substring(3);
    }
    return '+992$digits';
  }

  String _formatTajikPhoneForDisplay(String raw) {
    final phone = _normalizeTajikPhone(raw);
    final national = phone.substring(4);
    if (national.length != 9) return phone;
    return '+992 ${national.substring(0, 2)} ${national.substring(2, 5)} ${national.substring(5)}';
  }

  bool _isValidTajikPhone(String phone) {
    return RegExp(r'^\+992\d{9}$').hasMatch(phone);
  }

  void _handleSendCode() {
    final phone = _normalizeTajikPhone(_phoneCtrl.text.trim());
    final l10n = context.read<LocalizationProvider>();

    if (!_isValidTajikPhone(phone)) {
      _showError(l10n.tr('auth_phone_invalid'));
      return;
    }

    context.read<AppStateProvider>().sendVerificationCode(
      phoneNumber: phone,
      onCodeSent: (_) {
        if (mounted) {
          setState(() => _isCodeStep = true);
          _codeFocusNodes[0].requestFocus();
          _showSuccess(l10n.tr('auth_code_sent'));
        }
      },
      onError: (err) {
        _showError(_translateError(err, context.read<LocalizationProvider>()));
      },
    );
  }

  void _handleVerifyCode() {
    final code = _fullCode;
    final l10n = context.read<LocalizationProvider>();
    if (code.length < 6) {
      _showError(l10n.tr('auth_code_invalid'));
      return;
    }
    context.read<AppStateProvider>().verifyCodeAndSignIn(
      smsCode: code,
      onError: (err) {
        _clearCode();
        _codeFocusNodes[0].requestFocus();
        _showError(_translateError(err, l10n));
      },
    );
  }
}
