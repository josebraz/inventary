
import 'package:inventary/model/ItemEntity.dart';

abstract class ItemState {}

class ItemUninitializedState extends ItemState {}
class ItemFetchingState extends ItemState {}

class ItemFetchedState extends ItemState {
  final List<ItemEntity> items;
  ItemFetchedState(this.items);
}
class ItemErrorState extends ItemState {}

class ItemEmptyState extends ItemState {}