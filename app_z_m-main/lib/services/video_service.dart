import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video.dart';

class VideoService {
  final _client = Supabase.instance.client;

  /// Get public videos
  Future<List<Video>> getPublicVideos({
    String? category,
    String? searchQuery,
  }) async {
    var data = await _client
        .from('videos')
        .select('*, profiles!videos_author_id_fkey(full_name, avatar_url)')
        .eq('is_public', true)
        .order('created_at', ascending: false);

    List<Video> videos = (data as List).map((e) => Video.fromJson(e)).toList();

    if (category != null && category.isNotEmpty) {
      videos = videos.where((v) => v.category.toLowerCase() == category.toLowerCase()).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      videos = videos.where((v) =>
        v.title.toLowerCase().contains(q) ||
        v.description.toLowerCase().contains(q)
      ).toList();
    }

    return videos;
  }

  /// Get a single video by ID
  Future<Video?> getVideoById(String id) async {
    try {
      final data = await _client
          .from('videos')
          .select('*, profiles!videos_author_id_fkey(full_name, avatar_url)')
          .eq('id', id)
          .single();
      return Video.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Create a new video
  Future<Video?> createVideo(Video video) async {
    try {
      final data = await _client
          .from('videos')
          .insert(video.toInsertJson())
          .select('*, profiles!videos_author_id_fkey(full_name, avatar_url)')
          .single();
      return Video.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Delete a video
  Future<bool> deleteVideo(String id) async {
    try {
      await _client.from('videos').delete().eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get videos by author
  Future<List<Video>> getVideosByAuthor(String authorId) async {
    final data = await _client
        .from('videos')
        .select('*, profiles!videos_author_id_fkey(full_name, avatar_url)')
        .eq('author_id', authorId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Video.fromJson(e)).toList();
  }

  /// Get personalized videos for a user
  Future<List<Video>> getPersonalizedVideos(String userId) async {
    final data = await _client
        .from('videos')
        .select('*, profiles!videos_author_id_fkey(full_name, avatar_url)')
        .eq('target_user_id', userId)
        .eq('is_public', false)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Video.fromJson(e)).toList();
  }
}
