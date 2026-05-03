class AdminSettings {
  final String id;
  final bool freeResourceLimitEnabled;
  final int freeResourceLimit;
  final bool partialViewEnabled;
  final int partialViewPercentage;
  final bool exchangeRequired;
  final bool allowUserUploads;

  AdminSettings({
    this.id = '',
    this.freeResourceLimitEnabled = false,
    this.freeResourceLimit = 10,
    this.partialViewEnabled = false,
    this.partialViewPercentage = 30,
    this.exchangeRequired = false,
    this.allowUserUploads = true,
  });

  factory AdminSettings.fromJson(Map<String, dynamic> json) {
    return AdminSettings(
      id: json['id'] as String? ?? '',
      freeResourceLimitEnabled: json['free_resource_limit_enabled'] as bool? ?? false,
      freeResourceLimit: json['free_resource_limit'] as int? ?? 10,
      partialViewEnabled: json['partial_view_enabled'] as bool? ?? false,
      partialViewPercentage: json['partial_view_percentage'] as int? ?? 30,
      exchangeRequired: json['exchange_required'] as bool? ?? false,
      allowUserUploads: json['allow_user_uploads'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'free_resource_limit_enabled': freeResourceLimitEnabled,
      'free_resource_limit': freeResourceLimit,
      'partial_view_enabled': partialViewEnabled,
      'partial_view_percentage': partialViewPercentage,
      'exchange_required': exchangeRequired,
      'allow_user_uploads': allowUserUploads,
    };
  }

  AdminSettings copyWith({
    bool? freeResourceLimitEnabled,
    int? freeResourceLimit,
    bool? partialViewEnabled,
    int? partialViewPercentage,
    bool? exchangeRequired,
    bool? allowUserUploads,
  }) {
    return AdminSettings(
      id: id,
      freeResourceLimitEnabled: freeResourceLimitEnabled ?? this.freeResourceLimitEnabled,
      freeResourceLimit: freeResourceLimit ?? this.freeResourceLimit,
      partialViewEnabled: partialViewEnabled ?? this.partialViewEnabled,
      partialViewPercentage: partialViewPercentage ?? this.partialViewPercentage,
      exchangeRequired: exchangeRequired ?? this.exchangeRequired,
      allowUserUploads: allowUserUploads ?? this.allowUserUploads,
    );
  }
}
