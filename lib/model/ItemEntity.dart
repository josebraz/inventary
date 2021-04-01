
import 'dart:convert';

import 'package:inventary/model/BaseEntity.dart';


class ItemEntity extends BasicEntity {

  String name;

  String location;
  String description;
  String loan;

  List<String?> attachmentsPath;

  int parent;
  bool isFolder;

  ItemEntity({id, this.name = "", this.parent = -1, this.isFolder = false, this.location = "", this.description = "", this.loan = "", this.attachmentsPath = const []}) : super(id);

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'location': location,
    'description': description,
    'loan': loan,
    'attachmentsPath': json.encode(attachmentsPath),
    'parent': parent,
    'isFolder': isFolder ? 1 : 0,
  };

  static fromMap(Map<String, dynamic> map) => ItemEntity(
    id: map['id'],
    name: map['name'],
    location: map['location'],
    description: map['description'],
    loan: map['loan'],
    attachmentsPath: json.decode(map['attachmentsPath']).cast<String>(),
    parent: map['parent'],
    isFolder: map['isFolder'] != 0,
  );


  @override
  String toString() {
    return toMap().toString();
  }

  List<String?> get images {
    return attachmentsPath;
  }

}