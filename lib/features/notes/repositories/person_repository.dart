import '../../../core/database/database_service.dart';
import '../models/person.dart';
import '../models/money_transaction.dart';

class PersonRepository {
  final DatabaseService _db = DatabaseService();

  Future<List<Person>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(
      'people',
      orderBy: 'name ASC',
    );
    return maps.map((map) => Person.fromMap(map)).toList();
  }

  Future<Person?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'people',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Person.fromMap(maps.first);
  }

  Future<Person?> getByName(String name) async {
    final db = await _db.database;
    final maps = await db.query(
      'people',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (maps.isEmpty) return null;
    return Person.fromMap(maps.first);
  }

  Future<int> insert(Person person) async {
    final db = await _db.database;
    return await db.insert('people', person.toMap());
  }

  Future<int> update(Person person) async {
    final db = await _db.database;
    return await db.update(
      'people',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      'people',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get or create a person by name
  Future<Person> getOrCreate(String name) async {
    final existing = await getByName(name);
    if (existing != null) return existing;

    final person = Person(
      name: name,
      createdAt: DateTime.now(),
    );
    final id = await insert(person);
    return person.copyWith(id: id);
  }

  // Get balance for a person (positive = they owe me, negative = I owe them)
  Future<int> getBalance(int personId) async {
    final db = await _db.database;

    // Sum of money I gave (they owe me)
    final givenResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM money_transactions WHERE person_id = ? AND type = ?',
      [personId, 'given'],
    );
    final given = givenResult.first['total'] as int;

    // Sum of money I received (I owe them)
    final receivedResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM money_transactions WHERE person_id = ? AND type = ?',
      [personId, 'received'],
    );
    final received = receivedResult.first['total'] as int;

    return given - received;
  }

  // Get total commerce with a person
  Future<int> getTotalCommerce(int personId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM money_transactions WHERE person_id = ?',
      [personId],
    );
    return result.first['total'] as int;
  }

  // Get all transactions for a person
  Future<List<MoneyTransaction>> getTransactions(int personId) async {
    final db = await _db.database;
    final maps = await db.query(
      'money_transactions',
      where: 'person_id = ?',
      whereArgs: [personId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => MoneyTransaction.fromMap(map)).toList();
  }

  // Add a transaction
  Future<int> addTransaction(MoneyTransaction transaction) async {
    final db = await _db.database;
    return await db.insert('money_transactions', transaction.toMap());
  }

  // Delete a transaction
  Future<int> deleteTransaction(int transactionId) async {
    final db = await _db.database;
    return await db.delete(
      'money_transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // Get all people with their balances
  Future<List<Map<String, dynamic>>> getAllWithBalances() async {
    final people = await getAll();
    final result = <Map<String, dynamic>>[];

    for (final person in people) {
      final balance = await getBalance(person.id!);
      final totalCommerce = await getTotalCommerce(person.id!);
      result.add({
        'person': person,
        'balance': balance,
        'totalCommerce': totalCommerce,
      });
    }

    return result;
  }
}
