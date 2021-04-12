

import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/bloc/ItemBloc.dart';
import 'package:inventary/bloc/ItemSearchBloc.dart';
import 'package:inventary/bloc/event/ItemEvent.dart';
import 'package:inventary/bloc/state/ItemState.dart';
import 'package:inventary/model/ItemEntity.dart';
import 'package:inventary/view/CreateEditFolderScreen.dart';
import 'package:inventary/view/CreateEditItemScreen.dart';
import 'package:inventary/extensions/StringExtension.dart';
import 'package:inventary/extensions/StateExtension.dart';


class NewItemSearchScreen extends StatefulWidget {

  final startWithFilter = true;

  const NewItemSearchScreen({Key? key}) : super(key: key);

  @override
  NewItemSearchScreenState createState() => NewItemSearchScreenState();
}

class NewItemSearchScreenState extends State<NewItemSearchScreen> {

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _searchQueryController = TextEditingController();

  late bool _filterOpen;

  // filtros
  String _nameFilter = "";

  @override
  void initState() {
    super.initState();

    _filterOpen = widget.startWithFilter;
  }

  @override
  Widget build(BuildContext context) {
    return BackdropScaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      backLayer:  _buildFilters(),
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
        title: Text("Resultado da pesquisa"),
      ),
      frontLayer: BlocBuilder<ItemSearchBloc, ItemState>(
        bloc: BlocProvider.of<ItemSearchBloc>(context),
        builder: (context, state) {
          return _buildList(context, state);
        }
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return BackdropAppBar(
      leading: (_filterOpen) ? BackButton() : null,
      automaticallyImplyLeading: false,
      title: Text((_filterOpen) ? "Editar filtros" : "Resultado da Pesquisa"),
      actions: <Widget>[
        SearchBackdropToggleButton(
          onSearch: _searchQuery,
        ),
      ],
    );
  }

  // void _clearSearchQuery() {
  //   setState(() {
  //     _searchQueryController.clear();
  //
  //     nameFilter = "";
  //     _searchQuery();
  //   });
  // }

  ItemBloc get itemBloc => BlocProvider.of<ItemBloc>(context);

  Widget _buildList(BuildContext context, ItemState state) {
    if (state is ItemFetchingState) {
      return Center(child: CircularProgressIndicator());
    } else if (state is ItemFetchedState) {
      return ListView.builder(
        itemCount: state.items.length,
        itemBuilder: (context, i) {
          return _buildListItem(state.items[i]);
        },
      );
    } else {
      return _buildNoItems();
    }
  }

  Widget _buildListItem(ItemEntity item) {
    bool isSelected = false;
    return Dismissible(
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _delete(item);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 15.0),
        color: Colors.red,
        child: Icon(Icons.delete),
      ),
      key: ValueKey(item.id),
      child: Card(
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Colors.white70,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Hero(
            tag: "item_picture_${item.id}",
            child: item.getIcon(),
          ),
          title: Text(item.name),
          subtitle: Text(item.description.onEmpty("Sem descrição")),
          onTap: () {
            if (!isSelected) {
              if (item.isFolder) {
                setState(() {
                  // _changeFolder(item);
                });
              } else {
                _editItem(item);
              }
            }
          },
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            tooltip: "Opções para o item",
            itemBuilder: (context) => _buildListItemOptionMenu(item),
            onSelected: (String value) {
              _onItemOptionSelected(item, value);
            },
          ),
        ),
      ),
    );
  }

  List<PopupMenuItem<String>> _buildListItemOptionMenu(ItemEntity item) {
    return <PopupMenuItem<String>>[
      PopupMenuItem<String>(
        child: const Text('Editar'),
        value: 'Edit',
      ),
      PopupMenuItem<String>(
        child: const Text(
          'Deletar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        value: 'Delete',
      ),
    ];
  }

  Widget _buildNoItems() {
    return Center(
      child: Text("Sem itens"),
    );
  }

  void _onItemOptionSelected(ItemEntity item, String value) {
    if (value == 'Delete') {
      _delete(item);
    } else if (value == 'Edit') {
      _edit(item);
    }
  }

  void _edit(ItemEntity item) {
    if (item.isFolder) {
      _editFolder(item);
    } else {
      _editItem(item);
    }
  }

  void _delete(ItemEntity item) async {
    if (item.isFolder) {
      await _deleteFolder(item);
    } else {
      await _deleteItem(item);
    }
  }

  Future<void> _editItem(ItemEntity item) async {
    await Navigator.of(context)
        .pushNamed('/item', arguments: CreateEditItemArgs(item: item));
  }

  Future<void> _deleteItem(ItemEntity item) async {
    try {
      await itemBloc.delete(item);
      showSnack(
        "Item ${item.name} deletado com sucesso",
        actionText: "Desfazer",
        actionClicked: () async {
          await itemBloc.insert(item);
        },
      );
    } catch (e) {
      showSnack("Erro ao deletar o item ${item.name}");
    }
  }

  Future<void> _editFolder(ItemEntity item) async {
    await Navigator.of(context)
        .pushNamed('/folder', arguments: CreateEditFolderArgs(folder: item));
  }

  Future<int?> _showFolderNotEmptyAlert(
      ItemEntity folder,
      ItemEntity? pParentFolder,
      List<ItemEntity> children,
      ) async {
    var parentFolder = pParentFolder ?? ItemEntity.root();
    String message = "A categoria ${folder.name} contém alguns itens como "
        "${children.take(3).map((e) => e.name).join(", ")}. "
        "O que deseja fazer?";

    return showDialog<int?>(
      context: context,
      builder: (BuildContext context) {
        // retorna um objeto do tipo Dialog
        return AlertDialog(
          title: Text("A categoria não está vazia"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("Mover items para categoria ${parentFolder.name}"),
              onPressed: () => Navigator.of(context).pop(1),
            ),
            TextButton(
              child: Text(
                "Excluir Tudo",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(2),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFolder(ItemEntity folder) async {
    try {
      ItemEntity? parentFolder;
      List<ItemEntity> children = await itemBloc.list(folder.id!);

      if (children.isNotEmpty) {
        int response = await _showFolderNotEmptyAlert(
            folder, parentFolder, children) ?? 0;
        if (response == 1) {
          await itemBloc.changeParent(parentFolder?.id ?? -1, folder.id!);
        } else if (response == 2) {
          // TODO: eliminar resíduos de todos os descendentes dessa pasta
        } else {
          return;
        }
      }

      await itemBloc.delete(folder);

      showSnack(
        "Categoria ${folder.name} deletada com sucesso",
        actionText: "Desfazer",
        actionClicked: () async {
          await itemBloc.insert(folder);
        },
      );
    } catch (e) {
      print(e);
      showSnack("Erro ao deletar a categoria ${folder.name}");
    }
  }

  void _searchQuery() {
    BlocProvider.of<ItemSearchBloc>(context).add(
      SearchTextChangedItemEvent(
        _nameFilter
      )
    );
  }

  Widget _buildFilters() {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: Colors.white,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _searchQueryController,
                  autofocus: true,
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    icon: Icon(Icons.drive_file_rename_outline),
                    hintText: "Digite o nome do item",
                    labelText: "Nome de item",
                  ),
                  onChanged: (query) {
                    setState(() {
                      _nameFilter = query;
                    });
                  },
                ),
                SizedBox(height: 5),
              ]
            )
          )
        )
      ),
    );
  }
}

class SearchBackdropToggleButton extends StatelessWidget {

  final VoidCallback? onSearch;

  const SearchBackdropToggleButton({
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    bool isSearch = Backdrop.of(context).isBackLayerRevealed;
    return (isSearch)
      ? TextButton(
          onPressed: () {
            Backdrop.of(context).fling();
            onSearch?.call();
          },
          child: Text(
            "FILTRAR",
            style: TextStyle(color: Colors.white),
          ),
        )
      : IconButton(
          icon: Icon(Icons.search),
          color: Colors.white,
          onPressed: () {
            Backdrop.of(context).fling();
          },
        );
  }
}

