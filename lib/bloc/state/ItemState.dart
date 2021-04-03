
import 'package:inventary/model/ItemEntity.dart';

abstract class ItemState {}

class ItemUninitializedState extends ItemState {}
class ItemFetchingState extends ItemState {}

class ItemFetchedState extends ItemState {
  final int folderId;
  final List<ItemEntity> items;
  ItemFetchedState(this.items, this.folderId);
}
class ItemErrorState extends ItemState {}

class ItemEmptyState extends ItemState {}