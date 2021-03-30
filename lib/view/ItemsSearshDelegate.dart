import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/bloc/ItemSearchBloc.dart';
import 'package:inventary/bloc/event/ItemEvent.dart';
import 'package:inventary/bloc/state/ItemState.dart';

class ItemsSearchDelegate extends SearchDelegate {

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    BlocProvider.of<ItemSearchBloc>(context).add(SearchTextChangedItemEvent(query));

    return BlocBuilder<ItemSearchBloc, ItemState>(
      bloc: BlocProvider.of<ItemSearchBloc>(context),
      builder: (context, state) {
        if (state is ItemFetchingState) {
          return Center(child: CircularProgressIndicator());
        } else if (state is ItemFetchedState) {
          return ListView.builder(
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              var result = state.items[index];
              return ListTile(
                title: Text(result.name),
              );
            },
          );
        } else {
          return Center(
            child: Text("Sem itens"),
          );
        }
      }
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Column();
  }
}
