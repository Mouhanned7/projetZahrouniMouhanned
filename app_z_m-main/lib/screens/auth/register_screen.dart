import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/resource_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _universityController = TextEditingController();
  final _authService = AuthService();
  final _resourceService = ResourceService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  List<String> _knownUniversities = [];
  String? _selectedUniversity;
  bool _useCustomUniversity = false;

  static const String _customUniversityValue = '__custom__';

  @override
  void initState() {
    super.initState();
    _loadKnownUniversities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  Future<void> _loadKnownUniversities() async {
    try {
      final universities = await _resourceService.getKnownUniversities();
      if (!mounted) return;

      setState(() {
        _knownUniversities = universities;
        if (_knownUniversities.isNotEmpty && _selectedUniversity == null) {
          _selectedUniversity = _knownUniversities.first;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _knownUniversities = []);
    }
  }

  String _resolveUniversity() {
    if (_knownUniversities.isEmpty || _useCustomUniversity) {
      return _universityController.text.trim();
    }
    return (_selectedUniversity ?? '').trim();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        university: _resolveUniversity(),
      );
      if (mounted) {
        context.go('/resources');
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _errorMessage = 'Erreur lors de l\'inscription: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              diameter: 360,
              alignment: const Alignment(1.15, -0.9),
              color: AppTheme.secondaryColor,
              opacity: 0.2,
            ),
            _buildOrb(
              diameter: 430,
              alignment: const Alignment(-1.1, 0.95),
              color: AppTheme.accentColor,
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
                                child:
                                    _buildRegisterCard(showMobileBrand: false),
                              ),
                            ],
                          )
                        : _buildRegisterCard(showMobileBrand: true),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_add_rounded,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Créez votre espace de collaboration',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Inscrivez-vous pour partager vos travaux, valoriser votre parcours et apprendre avec votre communauté.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.76),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 26),
          _buildFeatureRow(
              Icons.apartment_rounded, 'Identité universitaire claire'),
          _buildFeatureRow(
              Icons.assignment_rounded, 'Publication rapide des ressources'),
          _buildFeatureRow(
              Icons.trending_up_rounded, 'Progression visible sur vos projets'),
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
              color: AppTheme.secondaryColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.secondaryColor),
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

  Widget _buildRegisterCard({required bool showMobileBrand}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
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
                const Icon(
                  Icons.person_add_rounded,
                  size: 42,
                  color: AppTheme.secondaryColor,
                ),
                const SizedBox(height: 14),
              ],
              const Text(
                'Inscription',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Créez votre compte et commencez à partager vos ressources.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.accentColor.withOpacity(0.42)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppTheme.accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              if (_knownUniversities.isEmpty)
                TextFormField(
                  controller: _universityController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Université',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Université requise'
                      : null,
                )
              else
                DropdownButtonFormField<String>(
                  value: _useCustomUniversity
                      ? _customUniversityValue
                      : _selectedUniversity,
                  items: [
                    ..._knownUniversities.map(
                      (university) => DropdownMenuItem<String>(
                        value: university,
                        child: Text(university),
                      ),
                    ),
                    const DropdownMenuItem<String>(
                      value: _customUniversityValue,
                      child: Text('Autre (saisie manuelle)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      if (value == _customUniversityValue) {
                        _useCustomUniversity = true;
                        _selectedUniversity = null;
                        _universityController.clear();
                      } else {
                        _useCustomUniversity = false;
                        _selectedUniversity = value;
                      }
                    });
                  },
                  validator: (value) {
                    if (_useCustomUniversity) return null;
                    if (value == null || value.isEmpty) {
                      return 'Université requise';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Université',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
              if (_knownUniversities.isNotEmpty && _useCustomUniversity) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _universityController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nouvelle université',
                    prefixIcon: Icon(Icons.edit_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Université requise'
                      : null,
                ),
              ],
              const SizedBox(height: 12),
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
                  onPressed: _isLoading ? null : _signUp,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(
                    _isLoading ? 'Création...' : 'Créer mon compte',
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
                    'Déjà un compte ? ',
                    style: TextStyle(color: Colors.white.withOpacity(0.65)),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(
                        color: AppTheme.secondaryColor,
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
