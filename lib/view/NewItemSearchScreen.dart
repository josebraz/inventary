import 'package:backdrop/backdrop.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/StatisticsManager.dart';
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
  final startWithFilter = false;
  final startNameFilterAsc = true;

  const NewItemSearchScreen({Key? key}) : super(key: key);

  @override
  NewItemSearchScreenState createState() => NewItemSearchScreenState();
}

class NewItemSearchScreenState extends State<NewItemSearchScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _searchQueryController = TextEditingController();

  late Future<List<ItemEntity>> _folderList;
  late Future<List<String>> _friendsList;
  List<int> _markedFolderList = [];
  List<String> _markedFriendList = [];

  late bool _filterOpen;
  late bool _nameFilterAsc;

  // filtros
  String _nameFilter = "";

  @override
  void initState() {
    super.initState();

    _filterOpen = widget.startWithFilter;
    _nameFilterAsc = widget.startNameFilterAsc;

    _folderList = itemSearchBloc.itemRepository.listRootFolders();
    _friendsList = itemSearchBloc.itemRepository.listFriends();

    BlocProvider.of<ItemSearchBloc>(context).add(SearchClearItemEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BackdropScaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      backLayer: _buildFilters(),
      onBackLayerConcealed: () {
        setState(() {
          _filterOpen = false;
        });
      },
      backLayerScrim: Colors.white,
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
          }),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return BackdropAppBar(
      leading: BackButton(),
      automaticallyImplyLeading: false,
      title: (_filterOpen) ? Text("Editar filtros") : _buildSearchField(),
      actions: <Widget>[
        SearchBackdropToggleButton(
          onSearch: _searchQuery,
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: Colors.white,
      ),
      child: TextField(
        controller: _searchQueryController,
        autofocus: true,
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: "Pesquisar por nome...",
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white30),
        ),
        style: TextStyle(color: Colors.white, fontSize: 16.0),
        onChanged: (query) {
          setState(() {
            _nameFilter = query;
            _searchQuery();
          });
        },
      ),
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
  ItemSearchBloc get itemSearchBloc => BlocProvider.of<ItemSearchBloc>(context);

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
            if (item.isFolder) {
              setState(() {
                // _changeFolder(item);
              });
            } else {
              _editItem(item);
            }
          },
          trailing: IconButton(
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
        int response =
            await _showFolderNotEmptyAlert(folder, parentFolder, children) ?? 0;
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
    var searchTextChangedItemEvent = SearchTextChangedItemEvent(
      nameFilter: _nameFilter,
      nameFilterAsc: _nameFilterAsc,
      friendsFilter: _markedFriendList,
      folderFilter: _markedFolderList,
    );
    StatisticsManager().analytics.logEvent(name: "search_event", parameters: {"query": searchTextChangedItemEvent});
    BlocProvider.of<ItemSearchBloc>(context).add(searchTextChangedItemEvent);
  }

  Widget _buildFilters() {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: Colors.white,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              SizedBox(height: 15),
              FilterTextField(
                controller: _searchQueryController,
                icon: Icons.drive_file_rename_outline,
                hintText: "Digite o nome do item",
                labelText: "Nome de item",
                ascStartOrder: widget.startNameFilterAsc,
                onChanged: (query) {
                  setState(() {
                    _nameFilter = query;
                  });
                },
                onOrderChange: (ascOrder) {
                  _nameFilterAsc = ascOrder;
                },
              ),
              FutureBuilder<List<ItemEntity>>(
                future: _folderList,
                builder: (BuildContext context, AsyncSnapshot<List<ItemEntity>> snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasData && snapshot.requireData.isEmpty) {
                    return SizedBox(height: 0);
                  }
                  return Column(
                    children: [
                      SizedBox(height: 15),
                      Divider(
                        color: Colors.blue.shade300,
                      ),
                      SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20, right: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Filtro por categorias principais:",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17.0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _markedFolderList.clear();
                                        print("CLICOU");
                                      });
                                    },
                                    child: Text(
                                      "LIMPAR",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17.0,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            SingleChildScrollView(
                              padding: EdgeInsets.symmetric(vertical: 3.0),
                              scrollDirection: Axis.horizontal,
                              dragStartBehavior: DragStartBehavior.down,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  SizedBox(width: 15),
                                  for (var item in snapshot.requireData)
                                    FilterItemOption(
                                      onChange: (bool marked) {
                                        setState(() {
                                          if (marked) {
                                            _markedFolderList.add(item.id!);
                                          } else {
                                            _markedFolderList.removeWhere((e) => e == item.id);
                                          }
                                        });
                                      },
                                      marked: _markedFolderList.any((e) => e == item.id),
                                      text: item.name,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15),
                    ],
                  );
                }
              ),
              FutureBuilder<List<String>>(
                future: _friendsList,
                builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasData && snapshot.requireData.isEmpty) {
                    return SizedBox(height: 0);
                  }
                  return Column(
                    children: [
                      Divider(
                        color: Colors.blue.shade300,
                      ),
                      SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20, right: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Filtrar itens emprestados para:",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17.0,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _markedFriendList.clear();
                                      });
                                    },
                                    child: Text(
                                      "LIMPAR",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17.0,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            SingleChildScrollView(
                              padding: EdgeInsets.symmetric(vertical: 3.0),
                              scrollDirection: Axis.horizontal,
                              dragStartBehavior: DragStartBehavior.down,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceEvenly,
                                children: <Widget>[
                                  SizedBox(width: 15),
                                  for (var friend in snapshot.requireData)
                                    FilterItemOption(
                                      onChange: (bool marked) {
                                        setState(() {
                                          if (marked) {
                                            _markedFriendList.add(friend);
                                          } else {
                                            _markedFriendList.removeWhere((e) => e == friend);
                                          }
                                        });
                                      },
                                      marked: _markedFriendList.contains(friend),
                                      text: friend,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15),
                    ],
                  );
                },
              ),
              Divider(
                color: Colors.blue.shade300,
              ),
              SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}

typedef OrderChanged = void Function(bool asc);

class FilterTextField extends StatefulWidget {
  final TextEditingController? controller;
  final IconData icon;
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final String? labelText;
  final OrderChanged? onOrderChange;
  final bool ascStartOrder;

  const FilterTextField({
    Key? key,
    this.controller,
    required this.icon,
    this.onChanged,
    this.hintText,
    this.labelText,
    this.onOrderChange,
    this.ascStartOrder = true,
  }) : super(key: key);

  @override
  FilterTextFieldState createState() => FilterTextFieldState();
}

class FilterTextFieldState extends State<FilterTextField> {
  late bool _ascOrder;

  @override
  void initState() {
    super.initState();
    _ascOrder = widget.ascStartOrder;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: widget.controller,
        autofocus: true,
        cursorColor: Colors.white,
        onChanged: widget.onChanged,
        style: TextStyle(
          color: Colors.white,
          fontSize: 17.0,
        ),
        decoration: InputDecoration(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          filled: true,
          prefixIcon: Icon(
            widget.icon,
            color: Colors.white,
          ),
          hintStyle: TextStyle(
            color: Colors.white70,
          ),
          labelStyle: TextStyle(color: Colors.white),
          fillColor: Colors.blue.shade400.withOpacity(0.7),
          hintText: widget.hintText,
          labelText: widget.labelText,
          suffixIcon: GestureDetector(
            onTap: () {
              setState(() {
                _ascOrder = !_ascOrder;
              });
              widget.onOrderChange?.call(_ascOrder);
            },
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Image.asset(
                (_ascOrder)
                    ? "assets/alpha_sort_icon.png"
                    : "assets/reverse_alpha_sort_icon.png",
                height: 10.0,
                width: 10.0,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef FilterMarkChanged = void Function(bool marked);

class FilterItemOption extends StatefulWidget {

  final String text;
  final FilterMarkChanged onChange;


  final textColorSelected = Colors.blue;
  final textColorNoSelected = Colors.white;
  final backgroundColorSelected = Colors.white;
  final backgroundColorNoSelected =  Colors.blue.shade300;
  final borderColor = Colors.blueAccent;

  final marked;

  FilterItemOption({
    Key? key,
    required this.text,
    required this.onChange,
    this.marked = false,
  }) : super(key: key);

  @override
  FilterItemOptionState createState() => FilterItemOptionState();
}

class FilterItemOptionState extends State<FilterItemOption> {

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10.0),
      child: GestureDetector(
        child: ElevatedButton(
          child: Text(
            widget.text,
            style: TextStyle(
              fontFamily: "Montserrat",
              fontWeight: FontWeight.w500,
              color: widget.marked ? widget.textColorSelected : widget.textColorNoSelected,
            ),
          ),
          style: ButtonStyle(
            padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(horizontal: 15.0)),
            backgroundColor: MaterialStateProperty.all<Color>(
                (widget.marked) ? widget.backgroundColorSelected : widget.backgroundColorNoSelected),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
                side: BorderSide(color: widget.borderColor),
              ),
            ),
          ),
          onPressed: () {
            setState(() {
              widget.onChange.call(!widget.marked);
            });
          },
        ),
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
              "PESQUISAR",
              style: TextStyle(color: Colors.white),
            ),
          )
        : IconButton(
            icon: Icon(Icons.filter_list),
            color: Colors.white,
            onPressed: () {
              Backdrop.of(context).fling();
            },
          );
  }
}
