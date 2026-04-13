class CloudinaryConfig {
  // TODO: Remplacer par vos identifiants Cloudinary
  static const String cloudName = 'drscomozb';
  static const String uploadPreset = 'flutter_uploads';

  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';
}
