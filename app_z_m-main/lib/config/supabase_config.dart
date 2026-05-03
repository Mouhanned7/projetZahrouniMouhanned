import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // TODO: Remplacer par vos identifiants Supabase
  static const String supabaseUrl = 'https://bpgktkozljhpxiujozxs.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_FhKnAM52FaNjh93O7NUmwQ_iz7Jq41L';

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
