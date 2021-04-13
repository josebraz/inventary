

import 'package:inventary/model/ItemEntity.dart';
import 'package:sqflite/sqflite.dart';

import 'EntityDAO.dart';

class ItemDAO extends EntityDAO<ItemEntity> {

  ItemDAO(Future<Database> database) : super("item", database);

  @override
  ItemEntity create(Map<String, dynamic> map) {
    return ItemEntity.fromMap(map);
  }

  Future<List<ItemEntity>> search(String name) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: "name LIKE ? COLLATE NOCASE",
        whereArgs: ['%$name%']
    );
    return List.generate(maps.length, (i) {
      return create(maps[i]);
    });
  }

  Future<List<ItemEntity>> list([int parent = -1]) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName, where: "parent = ?", whereArgs: [parent]);
    return List.generate(maps.length, (i) {
      return create(maps[i]);
    });
  }

  Future<void> changeParent(int to, int from) async {
    final Database db = await database;
    await db.update(
      tableName,
      { "parent": to },
      where: "parent = ?",
      whereArgs: [from]
    );
  }

  Future<void> move(int id, int newParent) async {
    final Database db = await database;
    await db.update(
      tableName,
      { "parent": newParent },
      where: "id = ?",
      whereArgs: [id]
    );
  }

}