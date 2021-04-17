
import 'package:inventary/model/BaseItemEntity.dart';

class FolderEntity extends BasicItemEntity {

  FolderEntity({int? id, name = "", parent = -1, rootParent = -1, isFolder = true}) : super(id, name, parent, rootParent, isFolder);

  @override
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'parent': parent,
    'isFolder': isFolder ? 1 : 0,
  };

  static fromMap(Map<String, dynamic> map) => FolderEntity(
    id: map['id'],
    name: map['name'],
    parent: map['parent'],
    isFolder: map['isFolder'] != 0,
  );

}