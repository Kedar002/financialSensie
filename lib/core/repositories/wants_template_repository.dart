import '../database/database_service.dart';
import '../models/wants_template.dart';

class WantsTemplateRepository {
  final DatabaseService _db = DatabaseService();

  // Template CRUD

  Future<List<WantsTemplate>> getAll() async {
    final db = await _db.database;
    final templateMaps = await db.query(
      'wants_templates',
      orderBy: 'created_at ASC',
    );

    final templates = <WantsTemplate>[];
    for (final map in templateMaps) {
      final items = await getItemsByTemplateId(map['id'] as int);
      templates.add(WantsTemplate.fromMap(map, items: items));
    }
    return templates;
  }

  Future<WantsTemplate?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'wants_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;

    final items = await getItemsByTemplateId(id);
    return WantsTemplate.fromMap(maps.first, items: items);
  }

  Future<int> insert(WantsTemplate template) async {
    final db = await _db.database;
    return await db.insert('wants_templates', template.toMap());
  }

  Future<int> update(WantsTemplate template) async {
    final db = await _db.database;
    return await db.update(
      'wants_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    // Items are deleted automatically via CASCADE
    return await db.delete(
      'wants_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Template Items CRUD

  Future<List<WantsTemplateItem>> getItemsByTemplateId(int templateId) async {
    final db = await _db.database;
    final maps = await db.query(
      'wants_template_items',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => WantsTemplateItem.fromMap(map)).toList();
  }

  Future<int> insertItem(WantsTemplateItem item) async {
    final db = await _db.database;
    return await db.insert('wants_template_items', item.toMap());
  }

  Future<int> updateItem(WantsTemplateItem item) async {
    final db = await _db.database;
    return await db.update(
      'wants_template_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await _db.database;
    return await db.delete(
      'wants_template_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Batch operations

  Future<void> insertItems(int templateId, List<WantsTemplateItem> items) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert('wants_template_items', item.copyWith(templateId: templateId).toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAllItems(int templateId) async {
    final db = await _db.database;
    await db.delete(
      'wants_template_items',
      where: 'template_id = ?',
      whereArgs: [templateId],
    );
  }

  Future<void> replaceItems(int templateId, List<WantsTemplateItem> items) async {
    await deleteAllItems(templateId);
    await insertItems(templateId, items);
  }
}
