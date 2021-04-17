
import 'package:inventary/model/ItemEntity.dart';

abstract class ItemEvent{}

class SearchTextChangedItemEvent extends ItemEvent {

  final String nameFilter;
  final bool nameFilterAsc;
  final List<String> friendsFilter;
  final List<int> folderFilter;

  SearchTextChangedItemEvent({
    required this.nameFilter,
    this.nameFilterAsc = true,
    this.friendsFilter = const [],
    this.folderFilter = const [],
  });
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