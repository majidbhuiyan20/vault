// lib/features/security/models/security_settings.dart

class SecuritySettings {
  final bool isPinSet;
  final String? hashedPin;
  final DateTime? createdAt;
  final DateTime? lastAccessedAt;

  SecuritySettings({
    required this.isPinSet,
    this.hashedPin,
    this.createdAt,
    this.lastAccessedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'isPinSet': isPinSet,
      'hashedPin': hashedPin,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'lastAccessedAt': lastAccessedAt?.millisecondsSinceEpoch,
    };
  }

  factory SecuritySettings.fromJson(Map<String, dynamic> json) {
    return SecuritySettings(
      isPinSet: json['isPinSet'] ?? false,
      hashedPin: json['hashedPin'],
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : null,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastAccessedAt'])
          : null,
    );
  }

  SecuritySettings copyWith({
    bool? isPinSet,
    String? hashedPin,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
  }) {
    return SecuritySettings(
      isPinSet: isPinSet ?? this.isPinSet,
      hashedPin: hashedPin ?? this.hashedPin,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }
}
