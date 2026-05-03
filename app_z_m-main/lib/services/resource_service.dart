import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resource.dart';

class ResourceService {
  final _client = Supabase.instance.client;

  Resource _fromRpcPendingRow(Map<String, dynamic> row) {
    final mapped = <String, dynamic>{
      'id': row['id'],
      'title': row['title'],
      'description': row['description'],
      'type': row['type'],
      'subject': row['subject'],
      'university': row['university'],
      'file_url': row['file_url'],
      'thumbnail_url': row['thumbnail_url'],
      'file_size': row['file_size'],
      'author_id': row['author_id'],
      'status': row['status'],
      'avg_rating': row['avg_rating'],
      'ratings_count': row['ratings_count'],
      'downloads_count': row['downloads_count'],
      'views_count': row['views_count'],
      'created_at': row['created_at'],
      'profiles': {
        'full_name': row['author_name'],
        'avatar_url': row['author_avatar'],
      },
    };

    return Resource.fromJson(mapped);
  }

  /// Fetch distinct universities from profiles/resources for dropdown suggestions.
  /// We keep the original casing of the first occurrence and deduplicate case-insensitively.
  Future<List<String>> getKnownUniversities() async {
    try {
      final profileRows = await _client
          .from('profiles')
          .select('university')
          .not('university', 'is', null)
          .neq('university', '');

      final resourceRows = await _client
          .from('resources')
          .select('university')
          .not('university', 'is', null)
          .neq('university', '');

      final byLower = <String, String>{};

      void collect(List rows) {
        for (final row in rows) {
          if (row is! Map<String, dynamic>) continue;
          final value = (row['university'] as String?)?.trim();
          if (value == null || value.isEmpty) continue;
          byLower.putIfAbsent(value.toLowerCase(), () => value);
        }
      }

      collect(profileRows as List);
      collect(resourceRows as List);

      final universities = byLower.values.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      return universities;
    } catch (_) {
      return [];
    }
  }

  /// Fetch approved resources with author profile info
  Future<List<Resource>> getResources({
    ResourceType? type,
    String? subject,
    String? university,
    String? searchQuery,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client
        .from('resources')
        .select('*, profiles!resources_author_id_fkey(full_name, avatar_url)')
        .eq('status', 'approved')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    if (type != null) {
      query = _client
          .from('resources')
          .select('*, profiles!resources_author_id_fkey(full_name, avatar_url)')
          .eq('status', 'approved')
          .eq('type', type.name)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
    }

    final data = await query;
    List<Resource> resources =
        (data as List).map((e) => Resource.fromJson(e)).toList();

    // Client-side filtering for search & subject
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      resources = resources
          .where((r) =>
              r.title.toLowerCase().contains(q) ||
              r.description.toLowerCase().contains(q) ||
              r.subject.toLowerCase().contains(q))
          .toList();
    }
    if (subject != null && subject.isNotEmpty) {
      resources = resources
          .where((r) => r.subject.toLowerCase() == subject.toLowerCase())
          .toList();
    }
    if (university != null && university.isNotEmpty) {
      resources = resources
          .where((r) => r.university.toLowerCase() == university.toLowerCase())
          .toList();
    }

    return resources;
  }

  /// Get a single resource by ID
  Future<Resource?> getResourceById(String id) async {
    try {
      final data = await _client
          .from('resources')
          .select('*, profiles!resources_author_id_fkey(full_name, avatar_url)')
          .eq('id', id)
          .single();
      // Views increment can be handled differently or implemented as an RPC later
      return Resource.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Create a new resource
  Future<Resource?> createResource(Resource resource) async {
    try {
      final data = await _client
          .from('resources')
          .insert(resource.toInsertJson())
          .select('*, profiles!resources_author_id_fkey(full_name, avatar_url)')
          .single();
      return Resource.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Delete a resource
  Future<bool> deleteResource(String id) async {
    try {
      await _client.from('resources').delete().eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get resources by author
  Future<List<Resource>> getResourcesByAuthor(String authorId) async {
    final data = await _client
        .from('resources')
        .select('*, profiles!resources_author_id_fkey(full_name, avatar_url)')
        .eq('author_id', authorId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Resource.fromJson(e)).toList();
  }

  /// Get pending resources (admin)
  Future<List<Resource>> getPendingResources() async {
    // Preferred path: RPC backed by SECURITY DEFINER SQL function to avoid RLS ambiguity.
    try {
      final rpcData = await _client.rpc('admin_pending_resources');
      final rpcRows = rpcData as List;
      return rpcRows
          .map((e) => _fromRpcPendingRow(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      // Fallback for environments where the RPC is not yet deployed.
      final data = await _client
          .from('resources')
          .select('*, profiles!resources_author_id_fkey(full_name, avatar_url)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      return (data as List).map((e) => Resource.fromJson(e)).toList();
    }
  }

  /// Approve or reject a resource (admin)
  Future<bool> updateResourceStatus(String id, ResourceStatus status) async {
    try {
      await _client
          .from('resources')
          .update({'status': status.name}).eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get total resources count
  Future<int> getResourcesCount() async {
    try {
      final data =
          await _client.from('resources').select('id').eq('status', 'approved');
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Count user's viewed resources (for limit enforcement)
  Future<int> getUserResourceViewCount(String userId) async {
    // For simplicity, we count from resource_exchanges
    try {
      final data = await _client
          .from('resource_exchanges')
          .select('id')
          .eq('user_id', userId);
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }
}
