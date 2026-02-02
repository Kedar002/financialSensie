class MoneyTransaction {
  final int? id;
  final int personId;
  final int amount; // in paise
  final String type; // 'given' or 'received'
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const MoneyTransaction({
    this.id,
    required this.personId,
    required this.amount,
    required this.type,
    this.note,
    required this.date,
    required this.createdAt,
  });

  MoneyTransaction copyWith({
    int? id,
    int? personId,
    int? amount,
    String? type,
    String? note,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return MoneyTransaction(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'person_id': personId,
      'amount': amount,
      'type': type,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MoneyTransaction.fromMap(Map<String, dynamic> map) {
    return MoneyTransaction(
      id: map['id'] as int?,
      personId: map['person_id'] as int,
      amount: map['amount'] as int,
      type: map['type'] as String,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
