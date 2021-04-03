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

  late List<ItemEntity> parentPath;
  late ItemEntity currentParent;

  @override
  void initState() {
    super.initState();

    parentPath = [ItemEntity(id: -1, name: "Principal")];
    currentParent = parentPath.first;
  }

  Future<bool> _onBackPressed() async {
    bool empty = parentPath.length == 1;
    if (!empty) {
      setState(() {
        parentPath.removeLast();
        currentParent = parentPath.last;
      });
    }
    return empty;
  }

  @override
  Widget build(BuildContext context) {
    changeFolder(currentParent);

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          leading: _buildBack(),
          title: Text("Categoria ${currentParent.name}"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(context: context, delegate: ItemsSearchDelegate());
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
    return new Card(
      child: ListTile(
        leading: item.icon,
        title: Text(item.name),
        subtitle: Text(item.description.onEmpty("Sem descrição")),
        onTap: () async {
          if (item.isFolder) {
            setState(() {
              changeFolder(item);
            });
          }
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

  void changeFolder(ItemEntity newParent) {
    if (!parentPath.any((element) => element.id == newParent.id)) {
      int index = parentPath.indexWhere((element) => element.id == currentParent.id);
      parentPath.removeRange(index + 1, parentPath.length);
      parentPath.add(newParent);
    }

    currentParent = newParent;
    BlocProvider.of<ItemBloc>(context).add(ListItemEvent(newParent.id!));
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

  Widget _buildNoItems() {
    return Center(
      child: Text("Sem itens"),
    );
  }

  Widget? _buildBack() {
    if (currentParent.id == -1) {
      return null;
    } else {
      return IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: _onBackPressed,
      );
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
          for (var parent in parentPath)
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
                    backgroundColor: MaterialStateProperty.all<Color>((parent.id == currentParent.id) ? Colors.lightBlueAccent : Colors.white),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      currentParent = parent;
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

  // actions
  Future<void> _addItem() async {
    await Navigator.of(context).pushNamed('/item',
        arguments: CreateEditItemArgs(parentItemId: currentParent.id));
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
        arguments: CreateEditFolderArgs(parentItemId: currentParent.id));
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
      ItemEntity? parentFolder = (parentPath.isEmpty || folder.parent == -1) ? null : parentPath.firstWhere((element) => element.id == folder.parent);
      List<ItemEntity> children = await BlocProvider.of<ItemBloc>(context).list(folder.id!);

      if (children.isNotEmpty) {
        int response = await showFolderNotEmptyAlert(folder, parentFolder, children) ?? 0;
        if (response == 1) {
          await BlocProvider.of<ItemBloc>(context).moveItems(parentFolder?.id ?? -1, folder.id!);
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
}
