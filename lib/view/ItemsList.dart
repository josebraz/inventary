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
  ItemsList({Key? key, required this.title, this.parentItemId = -1}) : super(key: key);

  final String title;
  final int parentItemId;

  @override
  _ItemsListState createState() => _ItemsListState();
}

class _ItemsListState extends State<ItemsList> {

  @override
  Widget build(BuildContext context) {

    BlocProvider.of<ItemBloc>(context).add(ListItemEvent(widget.parentItemId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(context: context, delegate: ItemsSearchDelegate());
              }
          )
        ],
      ),
      body: BlocBuilder<ItemBloc, ItemState>(
          bloc: BlocProvider.of<ItemBloc>(context),
          builder: (context, state) {
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
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
        ]
      )
    );
  }

  Widget _buildRow(ItemEntity item) {
    return new Card(
      child: ListTile(
        leading: item.attachmentsPath.isEmpty
            ? item.isFolder ? Icon(Icons.folder) : Icon(Icons.insert_drive_file_rounded)
            : Image.file(File(item.attachmentsPath.first!)),
        title: Text(item.name),
        subtitle: Text(item.description.onEmpty("Sem descrição")),
        onTap: () async {
          if (item.isFolder) {
            await Navigator.of(context).pushNamed('/', arguments: item.id);
            // TODO melhorar isso usando outro provider
            BlocProvider.of<ItemBloc>(context).add(ListItemEvent(widget.parentItemId));
          }
        },
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          itemBuilder: (context) => <PopupMenuItem<String>>[
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
          ],
          onSelected: (String value) {
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
          },
        ),
      ),
    );
  }

  Widget _buildNoItems() {
    return Center(
      child: Text("Sem itens"),
    );
  }

  // actions
  Future<void> _addItem() async {
    await Navigator.of(context).pushNamed('/item', arguments: CreateEditItemArgs(parentItemId: widget.parentItemId));
  }

  Future<void> _editItem(ItemEntity item) async {
    await Navigator.of(context).pushNamed('/item', arguments: CreateEditItemArgs(item: item));
  }

  Future<void> _deleteItem(ItemEntity item) async {
    try {
      BlocProvider.of<ItemBloc>(context).add(DeleteItemEvent(item.id));
      showSnack("Item ${item.name} deletado com sucesso",
          actionText: "Desfazer",
          actionClicked: () async {
            await BlocProvider.of<ItemBloc>(context).insert(item);
          });
    } catch (e) {
      showSnack("Erro ao deletar o item ${item.name}");
    }
  }

  Future<void> _addFolder() async {
    await Navigator.of(context).pushNamed('/folder', arguments: CreateEditFolderArgs(parentItemId: widget.parentItemId));
  }

  Future<void> _editFolder(ItemEntity item) async {
    await Navigator.of(context).pushNamed('/folder', arguments: CreateEditFolderArgs(folder: item));
  }

  Future<void> _deleteFolder(ItemEntity item) async {
    try {
      BlocProvider.of<ItemBloc>(context).add(DeleteItemEvent(item.id));
      showSnack("Categoria ${item.name} deletada com sucesso",
          actionText: "Desfazer",
          actionClicked: () async {
            await BlocProvider.of<ItemBloc>(context).insert(item);
          });
    } catch (e) {
      showSnack("Erro ao deletar a categoria ${item.name}");
    }
  }

}