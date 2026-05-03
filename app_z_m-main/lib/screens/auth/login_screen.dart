import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';

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
  bool _isLoading = false;
  bool _obscurePassword = true;
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
    } catch (e) {
      setState(() => _errorMessage = 'Email ou mot de passe incorrect');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 980;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF061120), Color(0xFF0A1D36), Color(0xFF102747)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            _buildOrb(
              diameter: 340,
              alignment: const Alignment(-1.1, -0.95),
              color: AppTheme.primaryColor,
              opacity: 0.22,
            ),
            _buildOrb(
              diameter: 460,
              alignment: const Alignment(1.15, 0.95),
              color: AppTheme.secondaryColor,
              opacity: 0.16,
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width > 700 ? 24 : 14,
                      vertical: size.width > 700 ? 20 : 12,
                    ),
                    child: isDesktop
                        ? Row(
                            children: [
                              Expanded(flex: 5, child: _buildBrandPanel()),
                              const SizedBox(width: 22),
                              Expanded(
                                flex: 4,
                                child: _buildAuthCard(showMobileBrand: false),
                              ),
                            ],
                          )
                        : _buildAuthCard(showMobileBrand: true),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrb({
    required double diameter,
    required Alignment alignment,
    required Color color,
    required double opacity,
  }) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(opacity),
                color.withOpacity(0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.darkCard.withOpacity(0.82),
            AppTheme.darkSurface.withOpacity(0.76),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.8)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Image.asset(
              'assets/logo (2).png',
              height: 118,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
              'KHEDMAA.com',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Centralisez vos PFE, rapports, présentations et retours de jury dans un espace fluide.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 26),
          _buildFeatureRow(Icons.upload_file_rounded, 'Publiez vos livrables'),
          _buildFeatureRow(
              Icons.search_rounded, 'Retrouvez rapidement une ressource'),
          _buildFeatureRow(Icons.groups_rounded, 'Collaborez entre filières'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.86),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard({required bool showMobileBrand}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showMobileBrand) ...[
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.75)),
                    ),
                    child: Image.asset(
                      'assets/logo (2).png',
                      height: 84,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const Text(
                'Connexion',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accédez à vos ressources académiques en quelques secondes.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 26),
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.accentColor.withOpacity(0.42)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.accentColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppTheme.accentColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email requis';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Mot de passe requis';
                  if (v.length < 6) return 'Minimum 6 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signIn,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(
                    _isLoading ? 'Connexion...' : 'Se connecter',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Pas encore de compte ? ',
                    style: TextStyle(color: Colors.white.withOpacity(0.65)),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text(
                      'S\'inscrire',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
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
    );
  }
}
