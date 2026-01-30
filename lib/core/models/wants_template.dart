class WantsTemplate {
  final int? id;
  final String name;
  final DateTime createdAt;
  final List<WantsTemplateItem> items;

  WantsTemplate({
    this.id,
    required this.name,
    DateTime? createdAt,
    this.items = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WantsTemplate.fromMap(Map<String, dynamic> map, {List<WantsTemplateItem>? items}) {
    return WantsTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items ?? [],
    );
  }

  WantsTemplate copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    List<WantsTemplateItem>? items,
  }) {
    return WantsTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  int get totalAmount {
    return items.fold(0, (sum, item) => sum + item.amount);
  }
}

class WantsTemplateItem {
  final int? id;
  final int templateId;
  final String name;
  final int amount;
  final DateTime createdAt;

  WantsTemplateItem({
    this.id,
    required this.templateId,
    required this.name,
    this.amount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'template_id': templateId,
      'name': name,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WantsTemplateItem.fromMap(Map<String, dynamic> map) {
    return WantsTemplateItem(
      id: map['id'] as int?,
      templateId: map['template_id'] as int,
      name: map['name'] as String,
      amount: map['amount'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  WantsTemplateItem copyWith({
    int? id,
    int? templateId,
    String? name,
    int? amount,
    DateTime? createdAt,
  }) {
    return WantsTemplateItem(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
