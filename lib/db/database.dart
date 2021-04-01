import 'dart:async';

import 'package:inventary/db/ItemDAO.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class AppDatabase {

  late Future<Database> db;

  static final AppDatabase _singleton = AppDatabase._internal();

  factory AppDatabase() {
    return _singleton;
  }

  AppDatabase._internal() {
    db = _openAppDatabase();
  }

  ItemDAO getItemDAO() {
    return ItemDAO(db);
  }

  Future<Database> _openAppDatabase() async {
    return openDatabase(
        join(await getDatabasesPath(), 'database.db'),
        onCreate: (db, version) {
          return db.execute(
            """CREATE TABLE item(
              id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
              name TEXT,
              location TEXT,
              description TEXT,
              loan TEXT,
              attachmentsPath TEXT,
              parent INTEGER,
              isFolder INTEGER
            )"""
          );
        },
        version: 1
    );
  }

}
