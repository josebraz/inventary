import 'dart:async';
import 'dart:ui';

import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/bloc/ItemBloc.dart';
import 'package:inventary/bloc/event/ItemEvent.dart';
import 'package:inventary/bloc/state/ItemState.dart';
import 'package:inventary/model/ItemEntity.dart';
import 'package:inventary/extensions/StateExtension.dart';
import 'package:inventary/extensions/StringExtension.dart';
import 'package:inventary/view/CreateEditFolder.dart';
import 'package:inventary/view/CreateEditItem.dart';
import 'package:inventary/view/ItemsSearshDelegate.dart';

class ItemsList extends StatefulWidget {
  ItemsList({Key? key}) : super(key: key);

  @override
  _ItemsListState createState() => _ItemsListState();
}

class _ItemsListState extends State<ItemsList> {

  late List<ItemEntity> _parentPath;
  late ItemEntity _currentParent;
  late List<ItemEntity> _itemsSelected;
  late bool _selectingFolderToMoveItems;

  @override
  void initState() {
    super.initState();

    _parentPath = [ItemEntity.root()];
    _currentParent = _parentPath.first;
    _itemsSelected = [];
    _selectingFolderToMoveItems = false;

    _changeFolder(_currentParent);
  }

  String get title {
    if ((_itemsSelected.isEmpty)) {
      return "Categoria ${_currentParent.name}";
    } else {
      if (_selectingFolderToMoveItems) {
        return "Selecione o destino";
      } else {
        return "Itens selecionados ${_itemsSelected.length}";
      }
    }
  }

  ItemBloc get itemBloc => BlocProvider.of<ItemBloc>(context);

  @override
  Widget build(BuildContext context) {
    timeDilation = 2.0;
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          leading: _buildAppBarBack(),
          title: Text(title),
          backgroundColor: (_itemsSelected.isNotEmpty) ? Colors.black54 : Colors.blue,
          actions: <Widget>[
            if (_itemsSelected.isEmpty) _buildNoSelectionAppBarActions(),
            if (_itemsSelected.isNotEmpty) _buildSelectionAppBarActions(),
          ],
        ),
        body: BlocBuilder<ItemBloc, ItemState>(
          bloc: itemBloc,
          builder: (context, state) {
            return Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildHeader(),
                ),
                Expanded(
                  child: _buildList(context, state),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
        floatingActionButton: _buildFloatingActionButtons(),
      ),
    );
  }

  Widget _buildNoSelectionAppBarActions() {
    return IconButton(
      icon: Icon(Icons.search),
      tooltip: "Pesquisar",
      onPressed: () {
        showSearch(context: context, delegate: ItemsSearchDelegate());
      },
    );
  }

  Widget _buildSelectionAppBarActions() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert),
      tooltip: "Mais opções para os itens selecionados",
      itemBuilder: (context) => <PopupMenuItem<String>>[
        PopupMenuItem<String>(
          child: const Text('Mover'),
          value: 'Move',
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
      ],
      onSelected: (String value) {
        if (value == 'Delete') {
          setState(() {
            _itemsSelected.forEach((element) {
              _onItemOptionSelected(element, "Delete");
            });
            _itemsSelected.clear();
          });
        } else if (value == 'Move') {
          setState(() {
            _selectingFolderToMoveItems = true;
          });
        }
      },
    );
  }

  Widget? _buildFloatingActionButtons() {
    if (_itemsSelected.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            heroTag: "add_folder",
            onPressed: _addFolder,
            tooltip: "Adicionar categoria",
            child: Icon(Icons.create_new_folder_rounded),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "add_item",
            onPressed: _addItem,
            tooltip: 'Adicionar Item',
            child: Icon(Icons.add_rounded),
          ),
        ],
      );
    } else {
      return null;
    }
  }

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
    bool isSelected = _itemsSelected.any((element) => element.id == item.id);
    return Dismissible(
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _delete(item);
        _itemsSelected.removeWhere((element) => element.id == item.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 15.0),
        color: Colors.red,
        child: Icon(Icons.delete),
      ),
      key: ValueKey(item.id),
      child: Card(
        elevation: (isSelected) ? 3.0 : 1.0,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: (isSelected) ? Colors.black38 : Colors.white70,
            width: (isSelected) ? 1.3 : 1,
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
            if (isSelected && !_selectingFolderToMoveItems) {
              setState(() {
                _itemsSelected.removeWhere((element) => element.id == item.id);
              });
            } else if (_itemsSelected.isNotEmpty && !_selectingFolderToMoveItems) {
              setState(() {
                if (!isSelected) {
                  _itemsSelected.add(item);
                }
              });
            } else if (!isSelected) {
              if (item.isFolder) {
                setState(() {
                  _changeFolder(item);
                });
              } else {
                _editItem(item);
              }
            }
          },
          onLongPress: () {
            setState(() {
              if (!isSelected) {
                _itemsSelected.add(item);
              }
            });
          },
          trailing: (isSelected) ? Icon(Icons.check) : PopupMenuButton<String>(
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

  Widget? _buildAppBarBack() {
    if (_currentParent.id != -1) {
      return IconButton(
        icon: Icon(Icons.arrow_back),
        tooltip: "Voltar",
        onPressed: _onBackPressed,
      );
    } else if (_itemsSelected.isNotEmpty) {
      return IconButton(
        icon: Icon(Icons.clear),
        tooltip: "Voltar",
        onPressed: _onBackPressed,
      );
    } else {
      return null;
    }
  }

  Widget _buildHeader() {
    final blueNoSelected = Colors.blue.shade400;
    return SingleChildScrollView(
      reverse: true,
      scrollDirection: Axis.horizontal,
      dragStartBehavior: DragStartBehavior.down,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          for (var parent in _parentPath) Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 5.0),
            child: GestureDetector(
              child: ElevatedButton.icon(
                icon: (parent.isRoot)
                    ? Icon(Icons.home, color: (parent.id == _currentParent.id) ? Colors.white : blueNoSelected)
                    : parent.getIcon((parent.id == _currentParent.id) ? Colors.white : blueNoSelected),
                label: Text(
                  "${parent.name}",
                  style: TextStyle(
                    fontFamily: "Montserrat",
                    fontWeight: FontWeight.w500,
                    color: (parent.id == _currentParent.id) ? Colors.white : blueNoSelected,
                  ),
                ),
                style: ButtonStyle(
                  padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.symmetric(horizontal: 15.0)),
                  backgroundColor: MaterialStateProperty.all<Color>((parent.id == _currentParent.id) ? Colors.lightBlue.shade200 : Colors.white),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                      side: BorderSide(color: blueNoSelected),
                    ),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _changeFolder(parent);
                  });
                },
              ),
              onLongPressEnd: (LongPressEndDetails details) {
                if (parent.isRoot) return;
                showMenu<String>(
                  context: context,
                  position: RelativeRect.fromLTRB(
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                      details.globalPosition.dx,
                      details.globalPosition.dy
                  ),
                  items: _buildListItemOptionMenu(parent),
                ).then((String? value) {
                  if (value != null) {
                    _onItemOptionSelected(parent, value);
                  }
                });
              },
            )
          )
        ],
      ),
    );
  }

  Widget? _buildBottomNavigationBar() {
    if (_selectingFolderToMoveItems) {
      return Container(
        height: 50.0,
        child: ElevatedButton.icon(
          icon: Icon(Icons.check),
          label: Text("Mover itens para cá"),
          onPressed: _moveSelectedItems,
          style: ButtonStyle(
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0.0),
              ),
            ),
          ),
        ),
      );
    } else {
      return null;
    }
  }

  // listeners
  Future<bool> _onBackPressed() async {
    bool finishApp = _parentPath.length == 1 && _itemsSelected.isEmpty;
    if (_selectingFolderToMoveItems) {
      setState(() {
        _selectingFolderToMoveItems = false;
        _itemsSelected.clear();
      });
    } else if (_itemsSelected.isNotEmpty) {
      setState(() {
        _itemsSelected.clear();
      });
    } else if (!finishApp) {
      setState(() {
        _parentPath.removeLast();
        _changeFolder(_parentPath.last);
      });
    }
    return finishApp;
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

  // actions
  Future<void> _addItem() async {
    await Navigator.of(context).pushNamed('/item',
        arguments: CreateEditItemArgs(parentItemId: _currentParent.id));
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

  Future<void> _addFolder() async {
    await Navigator.of(context).pushNamed('/folder',
        arguments: CreateEditFolderArgs(parentItemId: _currentParent.id));
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
      ItemEntity? parentFolder = (_parentPath.isEmpty || folder.parent == -1)
          ? null
          : _parentPath.firstWhere((element) => element.id == folder.parent);
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
      setState(() {
        _updateHeader(folder.id, removeInclude: true);
      });
      if (_currentParent.id == folder.id) {
        itemBloc.add(ListItemEvent(folder.parent));
      }

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

  Future<void> _moveSelectedItems() async {
    await _moveItems(_currentParent.id!);
    setState(() {
      _selectingFolderToMoveItems = false;
      _itemsSelected.clear();
    });
  }

  Future<void> _moveItems(int newParent) async {
    _itemsSelected.forEach((element) async {
      await itemBloc.move(element.id!, newParent);
    });
  }

  void _changeFolder(ItemEntity newParent) {
    if (!_parentPath.any((element) => element.id == newParent.id)) {
      _updateHeader(_currentParent.id);
      _parentPath.add(newParent);
    }
    _currentParent = newParent;
    itemBloc.add(ListItemEvent(newParent.id!));
  }

  void _updateHeader(int? removeStartId, {bool removeInclude = false}) {
    if (removeStartId != null) {
      int index = _parentPath.indexWhere((element) =>
      element.id == removeStartId);
      if (index >= 0) {
        _parentPath.removeRange(
            (removeInclude) ? index : index + 1, _parentPath.length);
      }
    }
  }
}

