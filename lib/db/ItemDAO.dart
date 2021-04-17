

import 'package:inventary/model/ItemEntity.dart';
import 'package:sqflite/sqflite.dart';

import 'EntityDAO.dart';

class ItemDAO extends EntityDAO<ItemEntity> {

  ItemDAO(Future<Database> database) : super("item", database);

  @override
  ItemEntity create(Map<String, dynamic> map) {
    return ItemEntity.fromMap(map);
  }

  Future<List<ItemEntity>> search({
    required String nameFilter,
    required bool nameFilterAsc,
  }) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: "name LIKE ? COLLATE NOCASE",
        whereArgs: ['%$nameFilter%'],
        orderBy: "name ${(nameFilterAsc) ? 'ASC' : 'DESC'}",
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

  Future<List<ItemEntity>> listRootFolders() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: "isFolder = 1 AND parent = -1",
      orderBy: "name",
    );
    return List.generate(maps.length, (i) {
      return create(maps[i]);
    });
  }

  Future<List<String>> listFriends() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      distinct: true,
      columns: ["loan"],
      where: "loan IS NOT NULL AND loan != ''",
    );
    return List.generate(maps.length, (i) {
      return maps[i]["loan"];
    });
  }

}