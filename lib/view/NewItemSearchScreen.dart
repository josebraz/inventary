

import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/bloc/ItemSearchBloc.dart';
import 'package:inventary/bloc/event/ItemEvent.dart';
import 'package:inventary/bloc/state/ItemState.dart';


class NewItemSearchScreen extends StatefulWidget {

  final startWithFilter = true;

  const NewItemSearchScreen({Key? key}) : super(key: key);

  @override
  NewItemSearchScreenState createState() => NewItemSearchScreenState();
}

class NewItemSearchScreenState extends State<NewItemSearchScreen> {

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchQueryController = TextEditingController();

  late bool _filterOpen;

  @override
  void initState() {
    super.initState();
    _filterOpen = widget.startWithFilter;
  }

  @override
  Widget build(BuildContext context) {
    return BackdropScaffold(
      key: scaffoldKey,
      appBar: _buildAppBar(),
      backLayer: Center(
        child: Text("Back Layer"),
      ),
      onBackLayerConcealed: () {
        setState(() {
          _filterOpen = false;
        });
      },
      onBackLayerRevealed: () {
        setState(() {
          _filterOpen = true;
        });
      },
      revealBackLayerAtStart: widget.startWithFilter,
      subHeader: BackdropSubHeader(
        title: Text("Sub Header"),
      ),
      frontLayer: BlocBuilder<ItemSearchBloc, ItemState>(
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
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {

    if (_filterOpen) {
      return BackdropAppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(),
        title: TextField(
          controller: _searchQueryController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Pesquisar item...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white30),
          ),
          style: TextStyle(color: Colors.white, fontSize: 16.0),
          onChanged: (query) {
            _updateSearchQuery(query);
          },
        ),
        actions: <Widget>[
          SearchBackdropToggleButton(
            onClear: () {
              if (_searchQueryController.text.isEmpty) {
                Navigator.pop(context);
                return;
              }
              _clearSearchQuery();
            },
          ),
        ],
      );
    } else {
      return BackdropAppBar(
        automaticallyImplyLeading: false,
        title: Text("Resultado da Pesquisa"),
        actions: <Widget>[
          SearchBackdropToggleButton()
        ],
      );
    }
  }

  void _clearSearchQuery() {
    setState(() {
      _searchQueryController.clear();
      _updateSearchQuery("");
    });
  }

  void _updateSearchQuery(String query) {
    BlocProvider.of<ItemSearchBloc>(context).add(SearchTextChangedItemEvent(query));
  }
}

class SearchBackdropToggleButton extends StatelessWidget {

  final VoidCallback? onClear;
  final VoidCallback? onSearch;

  const SearchBackdropToggleButton({
    this.onClear,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    bool isSearch = Backdrop.of(context).isBackLayerRevealed;
    return IconButton(
      icon: (isSearch) ? Icon(Icons.clear) : Icon(Icons.search),
      color: Colors.white,
      onPressed: () {
        Backdrop.of(context).fling();
        if (isSearch) {
          onSearch?.call();
        } else {
          onClear?.call();
        }
      },
    );
  }
}

