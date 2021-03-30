
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/bloc/event/ItemEvent.dart';
import 'package:inventary/bloc/state/ItemState.dart';
import 'package:inventary/model/ItemEntity.dart';
import 'package:inventary/repository/ItemRepository.dart';

class ItemBloc extends Bloc<ItemEvent, ItemState> {
  
  final ItemRepository itemRepository;

  ItemBloc(this.itemRepository) : assert(itemRepository != null), super(ItemUninitializedState());
  
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
    }
    try {
      if (event is DeleteItemEvent) {
        items.removeWhere((element) => element.id == event.deletedItemId);
      } else if (event is CreateItemEvent) {
        items.add(event.item);
      } else if (event is EditItemEvent) {
        int index = items.indexWhere((element) => element.id == event.editItem.id);
        if (index != -1) {
          items[index] = event.editItem;
        } else {
          items.add(event.editItem);
        }
      } else if (event is ListItemEvent) {
        yield ItemFetchingState();
        items = await itemRepository.list(event.parent);
      }
      if (items.length == 0) {
        yield ItemEmptyState();
      } else {
        yield ItemFetchedState(items);
      }
    } catch (_) {
      yield ItemErrorState();
    }
  }

  Future<void> delete(int id) async {
    try {
      await itemRepository.delete(id);
      add(DeleteItemEvent(id));
    } catch(e) {
      print("Error delete item $id");
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