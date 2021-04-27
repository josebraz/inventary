import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:inventary/StatisticsManager.dart';
import 'package:inventary/bloc/ItemBloc.dart';
import 'package:inventary/bloc/event/ItemEvent.dart';
import 'package:inventary/bloc/state/ItemState.dart';
import 'package:inventary/extensions/Utils.dart';
import 'package:inventary/model/ItemEntity.dart';
import 'package:inventary/extensions/StateExtension.dart';
import 'package:inventary/extensions/StringExtension.dart';
import 'package:inventary/view/CreateEditFolderScreen.dart';
import 'package:inventary/view/CreateEditItemScreen.dart';

class ItemsListScreen extends StatefulWidget {
  ItemsListScreen({Key? key}) : super(key: key);

  @override
  _ItemsListScreenState createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {

  late List<ItemEntity> _parentPath;
  late ItemEntity _currentParent;
  late List<ItemEntity> _itemsSelected;
  late bool _selectingFolderToMoveItems;
  late Future<bool> _isFreshInstall;

  @override
  void initState() {
    super.initState();

    _parentPath = [ItemEntity.root()];
    _currentParent = _parentPath.first;
    _itemsSelected = [];
    _selectingFolderToMoveItems = false;
    _isFreshInstall = Utils.isFreshInstall();

    _changeFolder(_currentParent);

    WidgetsBinding.instance?.addPostFrameCallback((_) async {
      if (await _isFreshInstall) {
        await Navigator.of(context).pushNamed('/startsearch');
        Utils.setFreshInstall();
      }
      final localEmail = await Utils.getUserEmail();
      if (localEmail == null) { // precisa pegar o email do usuário
        final newEmail = await _showEmailQuestion();
        if (newEmail != null) {
          StatisticsManager().analytics.setUserProperty(name: "email", value: newEmail);
          Utils.setUserEmail(newEmail);
        }
      }
    });
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
        Navigator.of(context).pushNamed('/search');
      },
    );
  }

  Widget _buildSelectionAppBarActions() {
    return IconButton(
      icon: Icon(Icons.more_vert),
      tooltip: "Mais opções para os itens selecionados",
      onPressed: () {
        showModalBottomSheet(
            context: context,
            builder: (BuildContext bc) {
              return Container(
                child: new Wrap(
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.drive_file_move),
                      title: Text('Mover'),
                      onTap: () {
                        setState(() {
                          _selectingFolderToMoveItems = true;
                        });
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.arrow_forward_outlined),
                      title: Text('Marcar como emprestado'),
                      onTap: () async {
                        await _showLoanTextField();
                        setState(() {
                          _itemsSelected.clear();
                        });
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.arrow_back_outlined),
                      title: Text('Marcar como devolvido'),
                      onTap: () async {
                        await _markNoLoan();
                        setState(() {
                          _itemsSelected.clear();
                        });
                      },
                    ),
                    ListTile(
                        leading: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        title: Text(
                          'Deletar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _itemsSelected.forEach((element) {
                              _onItemOptionSelected(element, "Delete");
                            });
                            _itemsSelected.clear();
                          });
                        }
                    ),
                  ],
                ),
              );
            }
        );
      }
    );
  }

  Future<void> _showLoanTextField({ItemEntity? item}) async {
    final controller = TextEditingController();
    String? loanTo = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Informe um contato'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: Text("Emprestar"),
            ),
          ],
          insetPadding: EdgeInsets.all(10),
          content: Container(
            width: double.infinity,
            child: TypeAheadField<String>(
              textFieldConfiguration: TextFieldConfiguration(
                autofocus: true,
                decoration: const InputDecoration(
                  icon: Icon(Icons.supervised_user_circle_sharp),
                  hintText: "Quem está com esses itens?",
                ),
                controller: controller,
                keyboardType: TextInputType.text,
              ),
              suggestionsCallback: (pattern) async {
                return await BlocProvider.of<ItemBloc>(context).itemRepository.listFriends(pattern);
              },
              transitionBuilder: (context, suggestionsBox, controller) {
                return suggestionsBox;
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              onSuggestionSelected: (suggestion) {
                Navigator.of(context).pop(suggestion);
              },
            ),
          ),
        );
      },
    );

    if (loanTo != null) {
      await _markLoan(loanTo, item: item);
    }
  }

  Future<void> _markLoan(String loanTo, {ItemEntity? item}) async {
    StatisticsManager().analytics.logEvent(name: "loan_event", parameters: {"loan_to": loanTo, "item": item});

    List<ItemEntity> list = (item != null) ? [item] : _itemsSelected;
    await itemBloc.loanTo(loanTo, list);
    showSnack(
      "Itens emprestados para $loanTo",
      actionText: "Desfazer",
      actionClicked: () async {
        await itemBloc.updateList(list);
      },
    );
  }

  Future<void> _markNoLoan({ItemEntity? item}) async {
    StatisticsManager().analytics.logEvent(name: "no_loan_event", parameters: {"item": item});

    List<ItemEntity> list = (item != null) ? [item] : _itemsSelected;
    await itemBloc.noLoanTo(list);
    showSnack(
      "Os itens estão de volta :)",
      actionText: "Desfazer",
      actionClicked: () async {
        await itemBloc.updateList(list);
      },
    );
  }

  Widget? _buildFloatingActionButtons() {
    if (_itemsSelected.isEmpty) {
      return SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        animatedIconTheme: IconThemeData(size: 28.0),
        backgroundColor: Colors.blue,
        visible: true,
        curve: Curves.bounceInOut,
        children: [
          SpeedDialChild(
            onTap: _addFolder,
            label: "Adicionar categoria",
            child: Icon(
              Icons.create_new_folder_rounded,
              color: Colors.grey,
            ),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(color: Colors.grey.shade600),
            labelBackgroundColor: Colors.white,
          ),
          SpeedDialChild(
            onTap: _addItem,
            label: "Adicionar item",
            child: Icon(
              Icons.add_rounded,
              color: Colors.grey,
            ),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(color: Colors.grey.shade600),
            labelBackgroundColor: Colors.white,
          ),
        ],
      );
    } else {
      return null;
    }
  }

  Future<String?> _showEmailQuestion() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Informe seu e-mail'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: Text("OK"),
            ),
          ],
          insetPadding: EdgeInsets.all(5),
          content: Container(
            width: double.infinity,
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "exemplo@gmail.com",
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, ItemState state) {
    if (state is ItemFetchingState) {
      return Center(child: CircularProgressIndicator());
    } else if (state is ItemFetchedState) {
      StatisticsManager().analytics.logEvent(name: "fetched_list_event", parameters: {"size": state.items.length});
      return ListView.builder(
        itemCount: state.items.length,
        itemBuilder: (context, i) {
          return _buildListItem(state.items[i]);
        },
      );
    } else {
      StatisticsManager().analytics.logEvent(name: "no_item_list_event");
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
              StatisticsManager().analytics.logEvent(name: "deselect_item_event", parameters: {"item": item});
              setState(() {
                _itemsSelected.removeWhere((element) => element.id == item.id);
              });
            } else if (_itemsSelected.isNotEmpty && !_selectingFolderToMoveItems) {
              StatisticsManager().analytics.logEvent(name: "select_item_event", parameters: {"item": item});
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
                StatisticsManager().analytics.logEvent(name: "select_item_event", parameters: {"item": item});
                _itemsSelected.add(item);
              }
            });
          },
          trailing: (isSelected) ? Icon(Icons.check) : IconButton(
            icon: Icon(Icons.more_vert),
            tooltip: "Opções para o item",
            onPressed: () {
              _showItemOptions(context, item);
            },
          ),
        ),
      ),
    );
  }

  void _showItemOptions(BuildContext context, ItemEntity item) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
          child: new Wrap(
            children: <Widget>[
              ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Editar'),
                  onTap: () {
                    _onItemOptionSelected(item, 'Edit');
                  }
              ),
              if (item.loan.isEmpty && !item.isFolder) ListTile(
                leading: Icon(Icons.arrow_forward_outlined),
                title: Text('Marcar como emprestado'),
                onTap: () {
                  _onItemOptionSelected(item, 'Mark_loan');
                },
              ),
              if (item.loan.isNotEmpty && !item.isFolder) ListTile(
                leading: Icon(Icons.arrow_back_outlined),
                title: Text('Marcar como devolvido'),
                onTap: () {
                  _onItemOptionSelected(item, 'Mark_no_loan');
                },
              ),
              ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  title: Text(
                    'Deletar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () {
                    _onItemOptionSelected(item, 'Delete');
                  }
              ),
            ],
          ),
        );
      }
    );
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
                _showItemOptions(context, parent);
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
        height: 60.0,
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
      StatisticsManager().analytics.logEvent(name: "cancel_select_folder_to_move_event");
      setState(() {
        _selectingFolderToMoveItems = false;
        _itemsSelected.clear();
      });
    } else if (_itemsSelected.isNotEmpty) {
      StatisticsManager().analytics.logEvent(name: "clear_selected_items_event");
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
    } else if (value == 'Mark_loan') {
      _showLoanTextField(item: item);
    } else if (value == 'Mark_no_loan') {
      _markNoLoan(item: item);
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
        arguments: CreateEditItemArgs(parentItem: _currentParent));
  }

  Future<void> _editItem(ItemEntity item) async {
    await Navigator.of(context)
        .pushNamed('/item', arguments: CreateEditItemArgs(item: item));
  }

  Future<void> _deleteItem(ItemEntity item) async {
    try {
      StatisticsManager().analytics.logEvent(name: "delete_item_event", parameters: {"item": item});
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
        arguments: CreateEditFolderArgs(parentItem: _currentParent));
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
    StatisticsManager().analytics.logEvent(name: "delete_folder_event", parameters: {"folder": folder});
    try {
      ItemEntity? parentFolder = (_parentPath.isEmpty || folder.parent == -1)
          ? null
          : _parentPath.firstWhere((element) => element.id == folder.parent);
      List<ItemEntity> children = await itemBloc.list(folder.id!);

      if (children.isNotEmpty) {
        int response = await _showFolderNotEmptyAlert(
            folder, parentFolder, children) ?? 0;
        if (response == 1) {
          StatisticsManager().analytics.logEvent(name: "change_parent_delete_folder_event", parameters: {"parentTo": parentFolder?.id, "parentFrom": folder.id});
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
    StatisticsManager().analytics.logEvent(name: "move_items_event", parameters: {"items": _itemsSelected, "newParent": _currentParent.id});
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
    StatisticsManager().analytics.logEvent(name: "change_folder_list_event", parameters: {"newParent": newParent});

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

