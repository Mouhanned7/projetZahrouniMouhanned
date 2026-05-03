import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/cloudinary_config.dart';

class CloudinaryService {
  /// Upload a file to Cloudinary and return the secure URL
  Future<String?> uploadFile({
    required Uint8List fileBytes,
    required String fileName,
    String? folder,
  }) async {
    try {
      final uri = Uri.parse(CloudinaryConfig.uploadUrl);
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      if (folder != null) {
        request.fields['folder'] = folder;
      }
      request.fields['public_id'] = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseBody);
        return jsonResponse['secure_url'] as String?;
      } else {
        throw Exception('Upload échoué (${response.statusCode}) : $responseBody');
      }
    } catch (e) {
      rethrow;
    }
  }
}
