
import 'BaseEntity.dart';

abstract class BasicItemEntity extends BasicEntity {

  String name;

  int parent;
  bool isFolder;

  BasicItemEntity(int? id, this.name, this.parent, this.isFolder) : super(id);

}