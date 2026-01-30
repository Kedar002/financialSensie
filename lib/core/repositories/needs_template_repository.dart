import '../database/database_service.dart';
import '../models/needs_template.dart';

class NeedsTemplateRepository {
  final DatabaseService _db = DatabaseService();

  // Template CRUD

  Future<List<NeedsTemplate>> getAll() async {
    final db = await _db.database;
    final templateMaps = await db.query(
      'needs_templates',
      orderBy: 'created_at ASC',
    );

    final templates = <NeedsTemplate>[];
    for (final map in templateMaps) {
      final items = await getItemsByTemplateId(map['id'] as int);
      templates.add(NeedsTemplate.fromMap(map, items: items));
    }
    return templates;
  }

  Future<NeedsTemplate?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      'needs_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;

    final items = await getItemsByTemplateId(id);
    return NeedsTemplate.fromMap(maps.first, items: items);
  }

  Future<int> insert(NeedsTemplate template) async {
    final db = await _db.database;
    return await db.insert('needs_templates', template.toMap());
  }

  Future<int> update(NeedsTemplate template) async {
    final db = await _db.database;
    return await db.update(
      'needs_templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    // Items are deleted automatically via CASCADE
    return await db.delete(
      'needs_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Template Items CRUD

  Future<List<NeedsTemplateItem>> getItemsByTemplateId(int templateId) async {
    final db = await _db.database;
    final maps = await db.query(
      'needs_template_items',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => NeedsTemplateItem.fromMap(map)).toList();
  }

  Future<int> insertItem(NeedsTemplateItem item) async {
    final db = await _db.database;
    return await db.insert('needs_template_items', item.toMap());
  }

  Future<int> updateItem(NeedsTemplateItem item) async {
    final db = await _db.database;
    return await db.update(
      'needs_template_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await _db.database;
    return await db.delete(
      'needs_template_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Batch operations

  Future<void> insertItems(int templateId, List<NeedsTemplateItem> items) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert('needs_template_items', item.copyWith(templateId: templateId).toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteAllItems(int templateId) async {
    final db = await _db.database;
    await db.delete(
      'needs_template_items',
      where: 'template_id = ?',
      whereArgs: [templateId],
    );
  }

  Future<void> replaceItems(int templateId, List<NeedsTemplateItem> items) async {
    await deleteAllItems(templateId);
    await insertItems(templateId, items);
  }
}
