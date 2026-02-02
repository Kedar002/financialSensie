class Person {
  final int? id;
  final String name;
  final DateTime createdAt;

  const Person({
    this.id,
    required this.name,
    required this.createdAt,
  });

  Person copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
