import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/resource.dart';

class ResourceStorageService {
  final _client = Supabase.instance.client;
  static const String bucketName = 'resources';

  Future<String> uploadResourceFile({
    required Uint8List fileBytes,
    required String fileName,
    required ResourceType type,
    required String userId,
  }) async {
    final safeFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final objectPath =
        '${type.name}/$userId/${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

    await _client.storage.from(bucketName).uploadBinary(
          objectPath,
          fileBytes,
          fileOptions: const FileOptions(upsert: false),
        );

    return _client.storage.from(bucketName).getPublicUrl(objectPath);
  }

  String buildDownloadUrl(String rawUrl, {String? preferredFileName}) {
    if (rawUrl.contains('/storage/v1/object/public/$bucketName/')) {
      final separator = rawUrl.contains('?') ? '&' : '?';
      if (preferredFileName != null && preferredFileName.isNotEmpty) {
        return '$rawUrl${separator}download=${Uri.encodeComponent(preferredFileName)}';
      }
      return '$rawUrl${separator}download=1';
    }

    if (rawUrl.contains('/upload/')) {
      return rawUrl.replaceFirst('/upload/', '/upload/fl_attachment/');
    }

    return rawUrl;
  }
}
