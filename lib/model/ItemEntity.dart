
import 'dart:convert';

import 'package:inventary/model/BaseItemEntity.dart';

class ItemEntity extends BasicItemEntity {

  String location;
  String description;
  String loan;

  List<String?> attachmentsPath;

  ItemEntity({id, name = "", parent = -1, isFolder = false, this.location = "", this.description = "", this.loan = "", this.attachmentsPath = const []}) : super(id, name, parent, isFolder);

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