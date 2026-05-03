import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';

class AuthService {
  final _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String university = '',
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );

    // Update profile with university
    if (response.user != null && university.isNotEmpty) {
      await _client
          .from('profiles')
          .update({'university': university, 'full_name': fullName})
          .eq('id', response.user!.id);
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Profile?> getCurrentProfile() async {
    if (currentUserId == null) return null;
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', currentUserId!)
        .single();
    return Profile.fromJson(data);
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (currentUserId == null) return;
    await _client
        .from('profiles')
        .update(updates)
        .eq('id', currentUserId!);
  }
}
