
import 'package:sqflite/sqflite.dart';

import '../model/BaseEntity.dart';

typedef Creator<T> = T Function(Map<String, dynamic> map);

abstract class EntityDAO<T extends BasicEntity> {

  final Future<Database> database;
  final String tableName;

  EntityDAO(this.tableName, this.database);

  Future<int> insert(T entity) async {
    final Database db = await database;
    return await db.insert(
      tableName,
      entity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(T entity) async {
    final Database db = await database;
    await db.update(
      tableName,
      entity.toMap(),
      where: "id = ?",
      whereArgs: [entity.id],
    );
  }

  Future<void> updateList(List<T> entities) async {
    final Database db = await database;
    Iterable<Future<int>> list = entities.map((entity) {
      return db.update(
        tableName,
        entity.toMap(),
        where: "id = ?",
        whereArgs: [entity.id],
      );
    });
    await Future.wait(list);
  }

  Future<void> delete(int id) async {
    final Database db = await database;
    await db.delete(
      tableName,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<List<T>> listAll() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return create(maps[i]);
    });
  }

  T create(Map<String, dynamic> map);

}