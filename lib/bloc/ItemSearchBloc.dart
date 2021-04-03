
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/bloc/event/ItemEvent.dart';
import 'package:inventary/bloc/state/ItemState.dart';
import 'package:inventary/model/ItemEntity.dart';
import 'package:inventary/repository/ItemRepository.dart';

class ItemSearchBloc extends Bloc<ItemEvent, ItemState> {
  
  final ItemRepository itemRepository;

  ItemSearchBloc(this.itemRepository) : super(ItemUninitializedState());
  
  @override
  void onTransition(Transition<ItemEvent, ItemState> transition) {
    super.onTransition(transition);
    print(transition);
  }

  @override
  Stream<ItemState> mapEventToState(ItemEvent event) async* {
    List<ItemEntity> items = [];
    try {
      if (event is SearchTextChangedItemEvent) {
        yield ItemFetchingState();
        items = await itemRepository.search(event.searchTerm);
      }
      if (items.length == 0) {
        yield ItemEmptyState();
      } else {
        yield ItemFetchedState(items, -1);
      }
    } catch (_) {
      yield ItemErrorState();
    }
  }

}