
import 'BaseEntity.dart';

abstract class BasicItemEntity extends BasicEntity {

  String name;

  int parent;
  int rootParent;
  bool isFolder;

  BasicItemEntity(int? id, this.name, this.parent, this.rootParent, this.isFolder) : super(id);

}