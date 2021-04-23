
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/bloc/event/ItemEvent.dart';
import 'package:inventary/bloc/state/ItemState.dart';
import 'package:inventary/model/ItemEntity.dart';
import 'package:inventary/repository/ItemRepository.dart';

class ItemBloc extends Bloc<ItemEvent, ItemState> {
  
  final ItemRepository itemRepository;

  int currentFolder = -1;

  ItemBloc(this.itemRepository) : super(ItemUninitializedState());

  List<ItemEntity> get itemsList {
    if (state is ItemFetchedState) {
      return (state as ItemFetchedState).items;
    } else {
      return [];
    }
  }
  
  @override
  void onTransition(Transition<ItemEvent, ItemState> transition) {
    super.onTransition(transition);
    print(transition);
  }

  @override
  Stream<ItemState> mapEventToState(ItemEvent event) async* {
    List<ItemEntity> items = itemsList;
    if (state is ItemFetchedState) {
      if (items.isEmpty) {
        currentFolder = -1;
      } else {
        currentFolder = items.first.parent;
      }
    }

    try {
      if (event is DeleteItemEvent) {
        if (event.deletedItem.parent == currentFolder) {
          items.removeWhere((element) => element.id == event.deletedItem.id);
        }
      } else if (event is CreateItemEvent) {
        if (event.item.parent == currentFolder) {
          items.add(event.item);
        }
      } else if (event is EditItemEvent) {
        if (event.editItem.parent == currentFolder) {
          int index = items.indexWhere((element) => element.id == event.editItem.id);
          if (index != -1) {
            items[index] = event.editItem;
          } else {
            items.add(event.editItem);
          }
        }
      } else if (event is ListItemEvent) {
        currentFolder = event.parent;
        yield ItemFetchingState();
        items = await itemRepository.list(currentFolder);
      } else if (event is RefreshItemEvent) {
        yield ItemFetchingState();
        items = await itemRepository.list(items.length == 0 ? -1 : items.first.parent);
      }
      if (items.length == 0) {
        yield ItemEmptyState();
      } else {
        yield ItemFetchedState(items, items.first.parent);
      }
    } catch (_) {
      yield ItemErrorState();
    }
  }

  Future<void> delete(ItemEntity item) async {
    try {
      await itemRepository.delete(item.id!);
      add(DeleteItemEvent(item));
    } catch(e) {
      print("Error delete item ${item.id}");
    }
  }

  Future<List<ItemEntity>> list([int parent = -1]) {
    return itemRepository.list(parent);
  }

  Future<void> changeParent(int parentTo, int parentFrom) async {
    try {
      await itemRepository.changeParent(parentTo, parentFrom);
      add(RefreshItemEvent());
    } catch(e) {
      print("Error moving items to $parentTo from $parentFrom");
    }
  }

  Future<void> move(int id, int newParent) async {
    try {
      await itemRepository.move(id, newParent);
      add(RefreshItemEvent());
    } catch(e) {
      print("Error moving items id $id newParent $newParent");
    }
  }

  Future<void> insert(ItemEntity item) async {
    try {
      var event = item.id == null ? CreateItemEvent(item) : EditItemEvent(item);
      int id = await itemRepository.insert(item);
      item.id = id;
      add(event);
    } catch(e) {
      print("Error insert item $item");
    }
  }

  Future<void> updateList(List<ItemEntity> items) async {
    try {
      await itemRepository.updateList(items);
      add(RefreshItemEvent());
    } catch(e) {
      print("Error update item $items");
    }
  }

  Future<void> loanTo(String loanTo, List<ItemEntity> list) async {
    try {
      await itemRepository.loanTo(loanTo, list);
      add(RefreshItemEvent());
    } catch(e) {
      print("Error loan item to $loanTo");
    }
  }

  Future<void> noLoanTo(List<ItemEntity> list) async {
    try {
      await itemRepository.noLoanTo(list);
      add(RefreshItemEvent());
    } catch(e) {
      print("Error no loan item to $loanTo");
    }
  }

}