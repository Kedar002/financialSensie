import '../../../core/database/database_service.dart';
import '../models/note.dart';

class NoteRepository {
  final DatabaseService _db = DatabaseService();

  Future<List<Note>> getAll() async {
    final db = await _db.database;
    final maps = await db.query(
      'notes',
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<Note?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  Future<int> insert(Note note) async {
    final db = await _db.database;
    return await db.insert('notes', note.toMap());
  }

  Future<int> update(Note note) async {
    final db = await _db.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Note>> search(String query) async {
    final db = await _db.database;
    final maps = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }
}
