
abstract class BasicEntity<T> {

  int? id;

  BasicEntity(this.id);

  Map<String, dynamic> toMap();
}