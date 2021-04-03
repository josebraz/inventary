
import 'package:inventary/model/ItemEntity.dart';

abstract class ItemEvent{}

class SearchTextChangedItemEvent extends ItemEvent {
  final String searchTerm;
  SearchTextChangedItemEvent(this.searchTerm);
}

class CreateItemEvent extends ItemEvent {
  final ItemEntity item;
  CreateItemEvent(this.item);
}

class EditItemEvent extends ItemEvent {
  final ItemEntity editItem;
  EditItemEvent(this.editItem);
}

class DeleteItemEvent extends ItemEvent {
  final ItemEntity deletedItem;
  DeleteItemEvent(this.deletedItem);
}

class RefreshItemEvent extends ItemEvent {
  RefreshItemEvent();
}

class ListItemEvent extends ItemEvent {
  final int parent;
  ListItemEvent([this.parent = -1]);
}