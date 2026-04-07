import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        _showError(AuthService.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await _authService.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(AuthService.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1B1A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo_vault.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Subtitle
                  Text(
                    _isLogin ? 'Inicia sesión' : 'Crea tu cuenta',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin
                        ? 'Accede a tu colección personal'
                        : 'Comienza tu archivo de arte',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Google Sign-In button
                  _buildGoogleButton(),

                  const SizedBox(height: AppSpacing.lg),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          'o continúa con email',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Email form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (!_isLogin) ...[
                          _buildField(
                            controller: _nameController,
                            hint: 'Nombre',
                            icon: Icons.person_outline,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Ingresa tu nombre'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _buildField(
                          controller: _emailController,
                          hint: 'Correo electrónico',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingresa tu correo';
                            }
                            if (!v.contains('@')) return 'Correo inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildField(
                          controller: _passwordController,
                          hint: 'Contraseña',
                          icon: Icons.lock_outline,
                          obscure: _obscurePassword,
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            if (!_isLogin && v.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleEmailAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1C1B1A),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppBorderRadius.md),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Color(0xFF1C1B1A),
                              ),
                            )
                          : Text(
                              _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Toggle login/register
                  GestureDetector(
                    onTap: () => setState(() {
                      _isLogin = !_isLogin;
                      _formKey.currentState?.reset();
                    }),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        children: [
                          TextSpan(
                            text: _isLogin
                                ? '¿No tienes cuenta? '
                                : '¿Ya tienes cuenta? ',
                          ),
                          TextSpan(
                            text: _isLogin ? 'Regístrate' : 'Inicia sesión',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
              height: 20,
              width: 20,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.g_mobiledata,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Continuar con Google',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 15,
          color: Colors.white.withValues(alpha: 0.35),
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: Colors.white.withValues(alpha: 0.4),
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}
