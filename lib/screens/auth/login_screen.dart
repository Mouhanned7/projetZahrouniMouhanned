import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import 'auth_design.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _rememberMe = false;
  bool _hidePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) context.go('/resources');
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Email ou mot de passe incorrect');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showProviderUnavailable(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider login is not configured yet.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: LoginSideFrame(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MobileBrand(),
              const Text(
                'Welcome back',
                style: TextStyle(
                  color: AuthColors.primary,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Continue your research journey with the global academic community.',
                style: TextStyle(
                  color: AuthColors.secondary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 56),
              Row(
                children: [
                  Expanded(
                    child: SocialButton(
                      text: 'Google',
                      onPressed: () => _showProviderUnavailable('Google'),
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'G',
                          style: TextStyle(
                            color: AuthColors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SocialButton(
                      text: 'GitHub',
                      onPressed: () => _showProviderUnavailable('GitHub'),
                      child: const Icon(
                        Icons.code_rounded,
                        size: 24,
                        color: Color(0xFF30313A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 52),
              Row(
                children: [
                  const Expanded(child: Divider(color: AuthColors.outline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      'OR CONTINUE WITH EMAIL',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AuthColors.outline)),
                ],
              ),
              const SizedBox(height: 40),
              if (_errorMessage != null) AuthErrorBox(message: _errorMessage!),
              const InputLabel(text: 'INSTITUTIONAL EMAIL'),
              const SizedBox(height: 8),
              CustomInputField(
                controller: _emailController,
                icon: Icons.email_rounded,
                hint: 'name@university.edu',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Email requis';
                  if (!email.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              const InputLabel(text: 'PASSWORD'),
              const SizedBox(height: 8),
              CustomInputField(
                controller: _passwordController,
                icon: Icons.lock_rounded,
                hint: 'Password',
                obscureText: _hidePassword,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: Colors.grey.shade600,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mot de passe requis';
                  }
                  if (value.length < 6) return 'Minimum 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        activeColor: AuthColors.primary,
                        onChanged: (value) {
                          setState(() => _rememberMe = value ?? false);
                        },
                      ),
                      const Text(
                        'Keep me logged in',
                        style: TextStyle(
                          color: AuthColors.textDark,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Password reset is not configured yet.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: AuthColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: AuthColors.primary.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Sign in to Workspace',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 56),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/register'),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        color: AuthColors.secondary,
                        fontSize: 16,
                      ),
                      children: [
                        TextSpan(text: 'New to the portal?  '),
                        TextSpan(
                          text: 'Create institutional account',
                          style: TextStyle(
                            color: AuthColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 54),
              const Divider(color: Color(0xFFE0E3E5)),
              const SizedBox(height: 28),
              const _SecurityStatus(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityStatus extends StatelessWidget {
  const _SecurityStatus();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 28,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OnlineDot(),
            SizedBox(width: 8),
            Text(
              'SYSTEMS ONLINE',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_rounded, color: Colors.grey, size: 18),
            SizedBox(width: 8),
            Text(
              'ISO 27001 SECURE',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AuthColors.green,
        shape: BoxShape.circle,
      ),
    );
  }
}
