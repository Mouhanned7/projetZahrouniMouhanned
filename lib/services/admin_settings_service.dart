import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_settings.dart';

class AdminSettingsService {
  final _client = Supabase.instance.client;

  /// Get current admin settings
  Future<AdminSettings> getSettings() async {
    try {
      final data =
          await _client.from('admin_settings').select().limit(1).single();
      return AdminSettings.fromJson(data);
    } catch (e) {
      return AdminSettings();
    }
  }

  /// Update admin settings
  Future<bool> updateSettings(AdminSettings settings) async {
    try {
      String targetId = settings.id;

      if (targetId.isEmpty) {
        final rows = await _client.from('admin_settings').select('id').limit(1);

        final list = rows as List;
        if (list.isNotEmpty) {
          targetId = (list.first as Map<String, dynamic>)['id'] as String;
        } else {
          await _client.from('admin_settings').insert(settings.toJson());
          return true;
        }
      }

      await _client
          .from('admin_settings')
          .update(settings.toJson())
          .eq('id', targetId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get platform statistics for admin dashboard
  Future<Map<String, int>> getStats() async {
    try {
      final resources = await _client.from('resources').select('id');
      final pending =
          await _client.from('resources').select('id').eq('status', 'pending');
      final users = await _client.from('profiles').select('id');
      final videos = await _client.from('videos').select('id');

      return {
        'totalResources': (resources as List).length,
        'pendingResources': (pending as List).length,
        'totalUsers': (users as List).length,
        'totalVideos': (videos as List).length,
      };
    } catch (e) {
      return {
        'totalResources': 0,
        'pendingResources': 0,
        'totalUsers': 0,
        'totalVideos': 0,
      };
    }
  }
}
