class NeedsCategory {
  final int? id;
  final String name;
  final int amount;
  final String icon;
  final DateTime createdAt;

  NeedsCategory({
    this.id,
    required this.name,
    this.amount = 0,
    required this.icon,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NeedsCategory.fromMap(Map<String, dynamic> map) {
    return NeedsCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      amount: map['amount'] as int? ?? 0,
      icon: map['icon'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  NeedsCategory copyWith({
    int? id,
    String? name,
    int? amount,
    String? icon,
    DateTime? createdAt,
  }) {
    return NeedsCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
