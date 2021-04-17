
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:inventary/model/BaseItemEntity.dart';

class ItemEntity extends BasicItemEntity {

  String location;
  String description;
  String loan;

  List<String?> attachmentsPath;

  ItemEntity({id, name = "", parent = -1, rootParent = -1, isFolder = false, this.location = "", this.description = "", this.loan = "", this.attachmentsPath = const []}) : super(id, name, parent, rootParent, isFolder);

  factory ItemEntity.root() => ItemEntity(
    id: -1,
    name: "Principal",
    description: "Categoria principal, não pode ser apagada",
    isFolder: true,
  );

  bool get isRoot => id == -1 && isFolder == true;

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
    'rootParent': rootParent,
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
    rootParent: map['rootParent'],
  );


  @override
  String toString() {
    return toMap().toString();
  }

  List<String?> get images {
    return attachmentsPath;
  }

  Widget getIcon([Color color = Colors.grey]) {
    if (attachmentsPath.isEmpty) {
      if (isFolder) {
        return Icon(
          Icons.folder,
          color: color,
        );
      } else {
        return Icon(
          Icons.insert_drive_file_rounded,
          color: color,
        );
      }
    } else {
      return Image.file(File(attachmentsPath.first!));
    }
  }

}