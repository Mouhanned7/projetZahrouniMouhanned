import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resource_rating.dart';

class RatingService {
  final _client = Supabase.instance.client;

  /// Get ratings for a resource
  Future<List<ResourceRating>> getRatings(String resourceId) async {
    final data = await _client
        .from('resource_ratings')
        .select('*, profiles!resource_ratings_user_id_fkey(full_name, avatar_url)')
        .eq('resource_id', resourceId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => ResourceRating.fromJson(e)).toList();
  }

  /// Submit or update a rating
  Future<bool> submitRating({
    required String resourceId,
    required String userId,
    required int rating,
    String comment = '',
  }) async {
    try {
      await _client.from('resource_ratings').upsert({
        'resource_id': resourceId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
      }, onConflict: 'resource_id,user_id');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user already rated a resource
  Future<ResourceRating?> getUserRating(String resourceId, String userId) async {
    try {
      final data = await _client
          .from('resource_ratings')
          .select()
          .eq('resource_id', resourceId)
          .eq('user_id', userId)
          .maybeSingle();
      if (data != null) {
        return ResourceRating.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
