import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/resource.dart';
import '../models/social_post.dart';

class SocialService {
  final _client = Supabase.instance.client;

  Future<List<SocialPost>> getFeed({String? currentUserId}) async {
    final postsData = await _client
        .from('social_posts')
        .select(
          '*, profiles!social_posts_author_id_fkey(full_name, avatar_url, university), resources!social_posts_linked_resource_id_fkey(id, title, type, subject), videos!social_posts_linked_video_id_fkey(id, title, thumbnail_url, category)',
        )
        .order('created_at', ascending: false);

    final posts = (postsData as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    if (posts.isEmpty) {
      return [];
    }

    final postIds = posts
        .map((item) => item['id'] as String)
        .where((id) => id.isNotEmpty)
        .toList();

    final likesData = await _client
        .from('social_post_likes')
        .select('post_id, user_id')
        .inFilter('post_id', postIds);

    final commentsData = await _client
        .from('social_post_comments')
        .select(
          '*, profiles!social_post_comments_user_id_fkey(full_name, avatar_url)',
        )
        .inFilter('post_id', postIds)
        .order('created_at', ascending: true);

    final attachmentsData = await _client
        .from('social_post_resources')
        .select(
          'post_id, resource_id, sort_order, resources!social_post_resources_resource_id_fkey(*)',
        )
        .inFilter('post_id', postIds)
        .order('sort_order', ascending: true);

    final likesByPost = <String, int>{};
    final likedByMe = <String, bool>{};

    for (final item in likesData as List) {
      final row = Map<String, dynamic>.from(item as Map);
      final postId = row['post_id'] as String? ?? '';
      final userId = row['user_id'] as String? ?? '';

      if (postId.isEmpty) continue;

      likesByPost[postId] = (likesByPost[postId] ?? 0) + 1;

      if (currentUserId != null && currentUserId == userId) {
        likedByMe[postId] = true;
      }
    }

    final commentsByPost = <String, List<SocialComment>>{};

    for (final item in commentsData as List) {
      final comment = SocialComment.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      commentsByPost.putIfAbsent(comment.postId, () => []).add(comment);
    }

    final attachmentsByPost = <String, List<Resource>>{};

    for (final item in attachmentsData as List) {
      final row = Map<String, dynamic>.from(item as Map);
      final postId = row['post_id'] as String? ?? '';
      final resourceData = row['resources'] as Map<String, dynamic>?;

      if (postId.isEmpty || resourceData == null) continue;

      attachmentsByPost.putIfAbsent(postId, () => []).add(
            Resource.fromJson(resourceData),
          );
    }

    return posts.map((row) {
      final postId = row['id'] as String? ?? '';
      final comments = commentsByPost[postId] ?? const <SocialComment>[];
      final attachments = attachmentsByPost[postId] ?? const <Resource>[];

      return SocialPost.fromJson(
        row,
        likesCount: likesByPost[postId] ?? 0,
        commentsCount: comments.length,
        isLikedByMe: likedByMe[postId] ?? false,
        comments: comments,
        attachments: attachments,
      );
    }).toList();
  }

  Future<SocialPost?> createPost({
    required String authorId,
    required String content,
    String? externalUrl,
    String? linkedResourceId,
    String? linkedVideoId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'author_id': authorId,
        'content': content.trim(),
        'external_url': (externalUrl ?? '').trim(),
      };

      final normalizedResourceId = (linkedResourceId ?? '').trim();
      if (normalizedResourceId.isNotEmpty) {
        payload['linked_resource_id'] = normalizedResourceId;
      }
      final normalizedVideoId = (linkedVideoId ?? '').trim();
      if (normalizedVideoId.isNotEmpty) {
        payload['linked_video_id'] = normalizedVideoId;
      }

      final data = await _client
          .from('social_posts')
          .insert(payload)
          .select(
            '*, profiles!social_posts_author_id_fkey(full_name, avatar_url, university), resources!social_posts_linked_resource_id_fkey(id, title, type, subject), videos!social_posts_linked_video_id_fkey(id, title, thumbnail_url, category)',
          )
          .single();

      return SocialPost.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> attachResourcesToPost({
    required String postId,
    required List<String> resourceIds,
  }) async {
    if (resourceIds.isEmpty) return;

    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < resourceIds.length; i++) {
      rows.add({
        'post_id': postId,
        'resource_id': resourceIds[i],
        'sort_order': i,
      });
    }

    await _client.from('social_post_resources').insert(rows);
  }

  Future<List<SocialContact>> getContacts({
    required String currentUserId,
    int limit = 12,
  }) async {
    final profilesData = await _client
        .from('profiles')
        .select('id, full_name, university, role, avatar_url, created_at')
        .neq('id', currentUserId)
        .order('created_at', ascending: false)
        .limit(limit);

    final rawContacts = (profilesData as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    if (rawContacts.isEmpty) return [];

    final messagesData = await _client
        .from('social_messages')
        .select('id, sender_id, recipient_id, content, created_at')
        .or(
          'sender_id.eq.$currentUserId,recipient_id.eq.$currentUserId',
        )
        .order('created_at', ascending: false);

    final latestByContactId = <String, SocialMessage>{};

    for (final item in messagesData as List) {
      final message = SocialMessage.fromJson(
        Map<String, dynamic>.from(item as Map),
      );
      final otherId = message.senderId == currentUserId
          ? message.recipientId
          : message.senderId;

      latestByContactId.putIfAbsent(otherId, () => message);
    }

    return rawContacts.map((row) {
      final id = row['id'] as String;
      final latest = latestByContactId[id];
      final latestAt = latest?.createdAt;

      return SocialContact(
        id: id,
        fullName: row['full_name'] as String? ?? '',
        university: row['university'] as String? ?? '',
        role: row['role'] as String? ?? 'user',
        avatarUrl: row['avatar_url'] as String? ?? '',
        lastMessagePreview: latest?.content ?? '',
        lastMessageAt: latestAt,
        isRecentlyActive: latestAt != null &&
            DateTime.now().difference(latestAt).inHours < 24,
      );
    }).toList();
  }

  Future<List<SocialMessage>> getConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final data = await _client
        .from('social_messages')
        .select('id, sender_id, recipient_id, content, created_at')
        .or(
          'and(sender_id.eq.$currentUserId,recipient_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,recipient_id.eq.$currentUserId)',
        )
        .order('created_at', ascending: true);

    return (data as List)
        .map((item) => SocialMessage.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<SocialMessage?> sendMessage({
    required String senderId,
    required String recipientId,
    required String content,
  }) async {
    try {
      final data = await _client
          .from('social_messages')
          .insert({
            'sender_id': senderId,
            'recipient_id': recipientId,
            'content': content.trim(),
          })
          .select('id, sender_id, recipient_id, content, created_at')
          .single();

      return SocialMessage.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<bool> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      final existing = await _client
          .from('social_post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from('social_post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } else {
        await _client.from('social_post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<SocialComment?> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    try {
      final data = await _client
          .from('social_post_comments')
          .insert({
            'post_id': postId,
            'user_id': userId,
            'content': content.trim(),
          })
          .select(
            '*, profiles!social_post_comments_user_id_fkey(full_name, avatar_url)',
          )
          .single();

      return SocialComment.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
