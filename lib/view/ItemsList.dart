import 'dart:async';

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

    _parentPath = [ItemEntity(id: -1, name: "Principal")];
    _currentParent = _parentPath.first;
    _itemsSelected = [];
    _selectingFolderToMoveItems = false;
  }

  Future<bool> _onBackPressed() async {
    bool finishApp = _parentPath.length == 1 && _itemsSelected.isEmpty;
    if (_itemsSelected.isNotEmpty) {
      setState(() {
        _itemsSelected.clear();
      });
    } else if (!finishApp) {
      setState(() {
        _parentPath.removeLast();
        _currentParent = _parentPath.last;
      });
    }
    return finishApp;
  }

  @override
  Widget build(BuildContext context) {
    _changeFolder(_currentParent);

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          leading: _buildBack(),
          title: Text(getTitle()),
          actions: <Widget>[
            if (_itemsSelected.isEmpty) IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(context: context, delegate: ItemsSearchDelegate());
              },
            ),
            if (_itemsSelected.isNotEmpty && !_selectingFolderToMoveItems) IconButton(
              icon: Icon(Icons.drive_file_move),
              onPressed: () {
                setState(() {
                  _selectingFolderToMoveItems = true;
                });
              },
            ),
            if (_itemsSelected.isNotEmpty && _selectingFolderToMoveItems) IconButton(
              icon: Icon(Icons.check),
              onPressed: () async {
                await _moveItems(_currentParent.id!);
                setState(() {
                  _selectingFolderToMoveItems = false;
                  _itemsSelected.clear();
                });
              },
            ),
            if (_itemsSelected.isNotEmpty && !_selectingFolderToMoveItems) IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  _itemsSelected.forEach((element) { _onItemOptionSelected(element, "Delete"); });
                  _itemsSelected.clear();
                });
              },
            ),
          ],
        ),
        body: BlocBuilder<ItemBloc, ItemState>(
          bloc: BlocProvider.of<ItemBloc>(context),
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
          }),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            FloatingActionButton(
              onPressed: _addFolder,
              tooltip: "Adicionar categoria",
              child: Icon(Icons.create_new_folder_rounded),
            ),
            SizedBox(height: 10),
            FloatingActionButton(
              onPressed: _addItem,
              tooltip: 'Adicionar Item',
              child: Icon(Icons.add_rounded),
            ),
          ],
        ),
      ),
    );
  }

  String getTitle() {
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

  Widget _buildList(BuildContext context, ItemState state) {
    if (state is ItemFetchingState) {
      return Center(child: CircularProgressIndicator());
    } else if (state is ItemFetchedState) {
      return ListView.builder(
        itemCount: state.items.length,
        itemBuilder: (context, i) {
          return _buildRow(state.items[i]);
        },
      );
    } else {
      return _buildNoItems();
    }
  }

  Widget _buildRow(ItemEntity item) {
    bool isSelected = _itemsSelected.any((element) => element.id == item.id);
    return new Card(
      child: ListTile(
        leading: (isSelected) ? Icon(Icons.check) : item.icon,
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
          } else if (item.isFolder && !isSelected) {
            setState(() {
              _changeFolder(item);
            });
          }
        },
        onLongPress: () {
          setState(() {
            if (!isSelected) {
              _itemsSelected.add(item);
            }
          });
        },
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          itemBuilder: (context) => _buildItemOptionMenu(item),
          onSelected: (String value) {
            _onItemOptionSelected(item, value);
          },
        ),
      ),
    );
  }

  List<PopupMenuItem<String>> _buildItemOptionMenu(ItemEntity item) {
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

  Widget? _buildBack() {
    if (_currentParent.id != -1 || _itemsSelected.isNotEmpty) {
      return IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: _onBackPressed,
      );
    } else {
      return null;
    }
  }

  Widget _buildHeader() {
    return SingleChildScrollView(
      reverse: true,
      scrollDirection: Axis.horizontal,
      dragStartBehavior: DragStartBehavior.down,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          for (var parent in _parentPath)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 5.0),
              child: GestureDetector(
                child: ElevatedButton.icon(
                  icon: (parent.id == -1) ? Icon(Icons.home, color: Colors.grey) : parent.icon,
                  label: Text(
                    "${parent.name}",
                    style: TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.symmetric(horizontal: 15.0)),
                    backgroundColor: MaterialStateProperty.all<Color>((parent.id == _currentParent.id) ? Colors.lightBlueAccent : Colors.white),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _currentParent = parent;
                    });
                  },
                ),
                onLongPressEnd: (LongPressEndDetails details) {
                  if (parent.id == -1) return;
                  showMenu<String>(
                    context: context,
                    position: RelativeRect.fromLTRB(
                        details.globalPosition.dx,
                        details.globalPosition.dy,
                        details.globalPosition.dx,
                        details.globalPosition.dy
                    ),
                    items: _buildItemOptionMenu(parent),
                  ).then((String? value) {
                    _onItemOptionSelected(parent, value!);
                  });
                },
              )
            )
        ],
      ),
    );
  }

  void _onItemOptionSelected(ItemEntity item, String value) {
    if (item.isFolder) {
      if (value == 'Edit') {
        _editFolder(item);
      } else if (value == 'Delete') {
        _deleteFolder(item);
      }
    } else {
      if (value == 'Edit') {
        _editItem(item);
      } else if (value == 'Delete') {
        _deleteItem(item);
      }
    }
  }

  void _changeFolder(ItemEntity newParent) {
    if (!_parentPath.any((element) => element.id == newParent.id)) {
      int index = _parentPath.indexWhere((element) => element.id == _currentParent.id);
      _parentPath.removeRange(index + 1, _parentPath.length);
      _parentPath.add(newParent);
    }

    _currentParent = newParent;
    BlocProvider.of<ItemBloc>(context).add(ListItemEvent(newParent.id!));
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
      await BlocProvider.of<ItemBloc>(context).delete(item);
      showSnack("Item ${item.name} deletado com sucesso",
          actionText: "Desfazer", actionClicked: () async {
        await BlocProvider.of<ItemBloc>(context).insert(item);
      });
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

  Future<int?> showFolderNotEmptyAlert(ItemEntity folder, ItemEntity? parentFolder, List<ItemEntity> children) async {
    String message = "A categoria ${folder.name} contém alguns itens como ${children.take(3).map((e) => e.name).join(", ")}. O que deseja fazer?";

    return showDialog<int?>(
      context: context,
      builder: (BuildContext context) {
        // retorna um objeto do tipo Dialog
        return AlertDialog(
          title: Text("A categoria não está vazia"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("Mover items para categoria ${parentFolder?.name ?? "Principal"}"),
              onPressed: () => Navigator.of(context).pop(1),
            ),
            TextButton(
              child: Text("Excluir Tudo", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.of(context).pop(2),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteFolder(ItemEntity folder) async {
    try {
      ItemEntity? parentFolder = (_parentPath.isEmpty || folder.parent == -1) ? null : _parentPath.firstWhere((element) => element.id == folder.parent);
      List<ItemEntity> children = await BlocProvider.of<ItemBloc>(context).list(folder.id!);

      if (children.isNotEmpty) {
        int response = await showFolderNotEmptyAlert(folder, parentFolder, children) ?? 0;
        if (response == 1) {
          await BlocProvider.of<ItemBloc>(context).changeParent(parentFolder?.id ?? -1, folder.id!);
        } else if (response == 2) {
          // TODO: eliminar resíduos de todos os descendentes dessa pasta
        } else {
          return;
        }
      }

      await BlocProvider.of<ItemBloc>(context).delete(folder);
      showSnack("Categoria ${folder.name} deletada com sucesso",
          actionText: "Desfazer", actionClicked: () async {
        await BlocProvider.of<ItemBloc>(context).insert(folder);
      });
    } catch (e) {
      print(e);
      showSnack("Erro ao deletar a categoria ${folder.name}");
    }
  }

  Future<void> _moveItems(int newParent) async {
    _itemsSelected.forEach((element) async {
      await BlocProvider.of<ItemBloc>(context).move(element.id!, newParent);
    });
  }
}
