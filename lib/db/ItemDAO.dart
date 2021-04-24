

import 'package:inventary/model/ItemEntity.dart';
import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';

import 'EntityDAO.dart';

class ItemDAO extends EntityDAO<ItemEntity> {

  final _log = Logger('ItemDAO');
  
  ItemDAO(Future<Database> database) : super("item", database);

  @override
  ItemEntity create(Map<String, dynamic> map) {
    return ItemEntity.fromMap(map);
  }

  Future<List<ItemEntity>> search({
    required String nameFilter,
    required bool nameFilterAsc,
    required List<String> friendsFilter,
    required List<int> folderFilter,
  }) async {
    _log.info("Start search - nameFilter $nameFilter nameFilterAsc $nameFilterAsc friendsFilter $friendsFilter folderFilter $folderFilter");
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
        tableName,
        where: "name LIKE ? COLLATE NOCASE"
            "${(friendsFilter.isNotEmpty) ? ' AND loan IN (${friendsFilter.map((e) => "'$e'").join(',')})' : ''}"
            "${(folderFilter.isNotEmpty) ? ' AND rootParent IN (${folderFilter.join(',')})' : ''}",
        whereArgs: ['%$nameFilter%'],
        orderBy: "name ${(nameFilterAsc) ? 'ASC' : 'DESC'}",
    );
    return List.generate(maps.length, (i) {
      return create(maps[i]);
    });
  }

  Future<List<ItemEntity>> list([int parent = -1]) async {
    _log.info("Start list - parent $parent");
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName, where: "parent = ?", whereArgs: [parent]);
    return List.generate(maps.length, (i) {
      return create(maps[i]);
    });
  }

  Future<void> changeParent(int to, int from) async {
    _log.info("Start changeParent - to $to from $from");
    final Database db = await database;
    await db.update(
      tableName,
      { "parent": to },
      where: "parent = ?",
      whereArgs: [from]
    );
  }

  Future<void> move(int id, int newParent) async {
    _log.info("Start move - id $id newParent $newParent");
    final Database db = await database;
    await db.update(
      tableName,
      { "parent": newParent },
      where: "id = ?",
      whereArgs: [id]
    );
  }

  Future<List<ItemEntity>> listRootFolders() async {
    _log.info("Start listRootFolders");
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

  Future<List<String>> listFriends([String startingWith = ""]) async {
    _log.info("Start listFriends - startingWith $startingWith");
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      distinct: true,
      columns: ["loan"],
      where: "loan IS NOT NULL AND loan != '' AND loan LIKE ? COLLATE NOCASE",
      whereArgs: ['%$startingWith'],
      orderBy: "name",
    );
    return List.generate(maps.length, (i) {
      return maps[i]["loan"];
    });
  }

  Future<void> loanTo(String loanTo, List<ItemEntity> itemsSelected) async {
    _log.info("Start loanTo - loanTo $loanTo itemsSelected $itemsSelected");
    final Database db = await database;
    await db.update(
        tableName,
        { "loan": loanTo },
        where: "id IN (${itemsSelected.map((e) => e.id).join(',')})",
    );
  }

  Future<void> noLoanTo(List<ItemEntity> itemsSelected) async {
    _log.info("Start noLoanTo - itemsSelected $itemsSelected");
    final Database db = await database;
    await db.update(
      tableName,
      { "loan": "" },
      where: "id IN (${itemsSelected.map((e) => e.id).join(',')})",
    );
  }

}