import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/bloc/ItemBloc.dart';
import 'package:inventary/bloc/ItemSearchBloc.dart';
import 'package:inventary/model/ItemEntity.dart';
import 'package:inventary/repository/ItemRepository.dart';
import 'package:inventary/view/CreateEditFolderScreen.dart';
import 'package:inventary/view/CreateEditItemScreen.dart';
import 'package:inventary/view/EditPictureScreen.dart';
import 'package:inventary/view/ItemsListScreen.dart';
import 'package:inventary/view/NewItemSearchScreen.dart';
import 'package:inventary/view/TakePictureScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

ThemeData theme = ThemeData(
  primaryColor: Colors.blue,
  primaryColorDark: Colors.blueGrey,
  backgroundColor: Colors.white10,
  fontFamily: 'PTSans',
);

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    var itemRepository = ItemRepository();
    return MultiBlocProvider(
      providers: [
        BlocProvider<ItemBloc>(
          create: (BuildContext context) => ItemBloc(itemRepository),
        ),
        BlocProvider<ItemSearchBloc>(
          create: (BuildContext context) => ItemSearchBloc(itemRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: theme,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          switch(settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (context) => ItemsListScreen(),
              );
            case '/item':
              final CreateEditItemArgs? args = settings.arguments as CreateEditItemArgs?;
              return MaterialPageRoute(
                builder: (context) {
                  rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                  return CreateEditItemScreen(
                    title: args?.item != null ? 'Editar ${args?.item?.name}' : 'Criar item',
                    startItem: args?.item ?? ItemEntity(id: null, isFolder: false, name: "", parent: args?.parentItem?.id ?? -1, rootParent: rootParent(args?.parentItem)),
                  );
                }
              );
            case '/folder':
              final CreateEditFolderArgs? args = settings.arguments as CreateEditFolderArgs?;
              return MaterialPageRoute(
                builder: (context) {
                  return CreateEditFolder(
                    title: args?.folder != null ? 'Editar ${args?.folder?.name}' : 'Criar Categoria',
                    startFolder: args?.folder ?? ItemEntity(id: null, isFolder: true, name: "", parent: args?.parentItem?.id ?? -1, rootParent: rootParent(args?.parentItem)),
                  );
                }
              );
            case '/takepicture':
              return MaterialPageRoute(
                  builder: (context) => TakePictureScreen()
              );
            case '/editpicture':
              final String? imagePath = settings.arguments as String?;
              return MaterialPageRoute(
                  builder: (context) => EditPictureScreen(imagePath)
              );
            case '/search':
              return MaterialPageRoute(
                  builder: (context) => NewItemSearchScreen()
              );
            default:
              return null;
          }
        },
      ),
    );
  }

  int rootParent(ItemEntity? parent) {
    if (parent != null) {
      if (parent.rootParent == -1) {
        return parent.id!;
      } else {
        return parent.rootParent;
      }
    }
    return -1;
  }

}
