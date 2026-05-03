import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/resource_service.dart';
import 'auth_design.dart';

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

  bool _hidePassword = true;
  bool _isLoading = false;
  bool _useCustomUniversity = false;
  String? _errorMessage;
  String? _selectedUniversity;
  List<String> _knownUniversities = [];

  static const _customUniversityValue = '__custom__';

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
        if (_knownUniversities.isNotEmpty) {
          _selectedUniversity = _knownUniversities.first;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _knownUniversities = []);
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
      if (mounted) context.go('/resources');
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Erreur inscription: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showProviderUnavailable(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider register is not configured yet.'),
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
                'Create account',
                style: TextStyle(
                  color: AuthColors.primary,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Join AcademicShare and start publishing, discovering, and organizing research resources.',
                style: TextStyle(
                  color: AuthColors.secondary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 44),
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
              const SizedBox(height: 42),
              Row(
                children: [
                  const Expanded(child: Divider(color: AuthColors.outline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      'OR REGISTER WITH EMAIL',
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
              const SizedBox(height: 34),
              if (_errorMessage != null) AuthErrorBox(message: _errorMessage!),
              const InputLabel(text: 'FULL NAME'),
              const SizedBox(height: 8),
              CustomInputField(
                controller: _nameController,
                icon: Icons.person_rounded,
                hint: 'Alex Morgan',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nom requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 24),
              const InputLabel(text: 'UNIVERSITY'),
              const SizedBox(height: 8),
              _buildUniversityField(),
              const SizedBox(height: 24),
              const InputLabel(text: 'PASSWORD'),
              const SizedBox(height: 8),
              CustomInputField(
                controller: _passwordController,
                icon: Icons.lock_rounded,
                hint: 'Minimum 6 characters',
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
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
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
                          'Create Workspace Account',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 46),
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        color: AuthColors.secondary,
                        fontSize: 16,
                      ),
                      children: [
                        TextSpan(text: 'Already registered?  '),
                        TextSpan(
                          text: 'Sign in to workspace',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUniversityField() {
    if (_knownUniversities.isEmpty) {
      return CustomInputField(
        controller: _universityController,
        icon: Icons.school_rounded,
        hint: 'University name',
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Universite requise';
          }
          return null;
        },
      );
    }

    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _useCustomUniversity
              ? _customUniversityValue
              : _selectedUniversity,
          items: [
            ..._knownUniversities.map(
              (university) => DropdownMenuItem<String>(
                value: university,
                child: Text(university, overflow: TextOverflow.ellipsis),
              ),
            ),
            const DropdownMenuItem<String>(
              value: _customUniversityValue,
              child: Text('Other university'),
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
            if (value == null || value.isEmpty) return 'Universite requise';
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(
              Icons.school_rounded,
              color: Color(0xFF777682),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AuthColors.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide:
                  const BorderSide(color: AuthColors.primary, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AuthColors.error),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: AuthColors.error, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (_useCustomUniversity) ...[
          const SizedBox(height: 14),
          CustomInputField(
            controller: _universityController,
            icon: Icons.edit_rounded,
            hint: 'University name',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Universite requise';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}
