import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
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
  List<ItemEntity> parentPath = [];

  ItemEntity? get currentParent {
    var length = parentPath.length;
    if (length > 0) {
      return parentPath.last;
    } else {
      return null;
    }
  }

  Future<bool> _onBackPressed() async {
    if (parentPath.isEmpty)
      return true;
    else {
      setState(() {
        parentPath.removeLast();
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    BlocProvider.of<ItemBloc>(context)
        .add(ListItemEvent(currentParent?.id ?? -1));

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          leading: _buildBack(),
          title: Text("Categoria ${currentParent?.name ?? "Principal"}"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(
                    context: context, delegate: ItemsSearchDelegate());
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
              child: Icon(Icons.folder),
            ),
            SizedBox(height: 10),
            FloatingActionButton(
              onPressed: _addItem,
              tooltip: 'Adicionar Item',
              child: Icon(Icons.add),
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
        leading: item.attachmentsPath.isEmpty
            ? item.isFolder
                ? Icon(Icons.folder)
                : Icon(Icons.insert_drive_file_rounded)
            : Image.file(File(item.attachmentsPath.first!)),
        title: Text(item.name),
        subtitle: Text(item.description.onEmpty("Sem descrição")),
        onTap: () async {
          if (item.isFolder) {
            setState(() {
              parentPath.add(item);
            });
            BlocProvider.of<ItemBloc>(context)
                .add(ListItemEvent(currentParent?.id ?? -1));
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
    if (parentPath.isEmpty) {
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
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 5.0),
            child: IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                setState(() {
                  parentPath.clear();
                });
              },
            ),
          ),
          for (var parent in parentPath)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 5.0),
              child: GestureDetector(
                child: ElevatedButton(
                  child: Text(
                    "${parent.name}",
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(EdgeInsets.symmetric(horizontal: 15.0)),
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            side: BorderSide(color: Colors.blue))),
                  ),
                  onPressed: () {
                    setState(() {
                      int index = parentPath
                          .indexWhere((element) => element.id == parent.id);
                      parentPath.removeRange(index + 1, parentPath.length);
                    });
                  },
                ),
                onLongPressEnd: (LongPressEndDetails details) {
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
        arguments: CreateEditItemArgs(parentItemId: currentParent?.id ?? -1));
  }

  Future<void> _editItem(ItemEntity item) async {
    await Navigator.of(context)
        .pushNamed('/item', arguments: CreateEditItemArgs(item: item));
  }

  Future<void> _deleteItem(ItemEntity item) async {
    try {
      await BlocProvider.of<ItemBloc>(context).delete(item.id!);
      BlocProvider.of<ItemBloc>(context).add(DeleteItemEvent(item.id));
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
        arguments: CreateEditFolderArgs(parentItemId: currentParent?.id ?? -1));
  }

  Future<void> _editFolder(ItemEntity item) async {
    await Navigator.of(context)
        .pushNamed('/folder', arguments: CreateEditFolderArgs(folder: item));
  }

  Future<void> _deleteFolder(ItemEntity item) async {
    try {
      await BlocProvider.of<ItemBloc>(context).delete(item.id!);
      BlocProvider.of<ItemBloc>(context).add(DeleteItemEvent(item.id));
      showSnack("Categoria ${item.name} deletada com sucesso",
          actionText: "Desfazer", actionClicked: () async {
        await BlocProvider.of<ItemBloc>(context).insert(item);
      });
    } catch (e) {
      showSnack("Erro ao deletar a categoria ${item.name}");
    }
  }
}
