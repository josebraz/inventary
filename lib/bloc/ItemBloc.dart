
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/bloc/event/ItemEvent.dart';
import 'package:inventary/bloc/state/ItemState.dart';
import 'package:inventary/model/ItemEntity.dart';
import 'package:inventary/repository/ItemRepository.dart';

class ItemBloc extends Bloc<ItemEvent, ItemState> {
  
  final ItemRepository itemRepository;

  int currentFolder = -1;

  ItemBloc(this.itemRepository) : super(ItemUninitializedState());
  
  @override
  void onTransition(Transition<ItemEvent, ItemState> transition) {
    super.onTransition(transition);
    print(transition);
  }

  @override
  Stream<ItemState> mapEventToState(ItemEvent event) async* {
    List<ItemEntity> items = [];
    if (state is ItemFetchedState) {
      items = (state as ItemFetchedState).items;
      currentFolder = items.first.parent;
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

  Future<void> moveItems(int to, int from) async {
    try {
      await itemRepository.moveItems(to, from);
      add(RefreshItemEvent());
    } catch(e) {
      print("Error moving items to $to from $from");
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

}