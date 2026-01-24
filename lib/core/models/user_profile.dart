class UserProfile {
  final int? id;
  final String name;
  final String currency;
  final String riskLevel;
  final int dependents;
  final int createdAt;
  final int updatedAt;

  const UserProfile({
    this.id,
    required this.name,
    this.currency = 'INR',
    this.riskLevel = 'moderate',
    this.dependents = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currency': currency,
      'risk_level': riskLevel,
      'dependents': dependents,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      currency: map['currency'] as String,
      riskLevel: map['risk_level'] as String,
      dependents: map['dependents'] as int,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? currency,
    String? riskLevel,
    int? dependents,
    int? createdAt,
    int? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      riskLevel: riskLevel ?? this.riskLevel,
      dependents: dependents ?? this.dependents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get emergencyFundMonths {
    switch (riskLevel) {
      case 'low':
        return 8;
      case 'high':
        return 4;
      default:
        return 6;
    }
  }
}
