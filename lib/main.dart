import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/bloc/ItemBloc.dart';
import 'package:inventary/bloc/ItemSearchBloc.dart';
import 'package:inventary/repository/ItemRepository.dart';
import 'package:inventary/view/CreateEditFolder.dart';
import 'package:inventary/view/CreateEditItem.dart';
import 'package:inventary/view/ItemsList.dart';
import 'package:inventary/view/TakePictureScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

ThemeData theme = ThemeData(
  primaryColor: Colors.blue,
  backgroundColor: Colors.white10,
  fontFamily: 'PTSans',
);

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
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          switch(settings.name) {
            case '/':
              final int parentItemId = settings.arguments as int? ?? -1;
              return MaterialPageRoute(
                builder: (context) => ItemsList(
                  title: 'Todos os Itens',
                  parentItemId: parentItemId,
                ),
              );
            case '/item':
              final CreateEditItemArgs? args = settings.arguments as CreateEditItemArgs?;
              return MaterialPageRoute(
                builder: (context) {
                  return CreateEditItem(
                    title: args!.item != null ? 'Editar ${args.item!.name}' : 'Criar item',
                    startItem: args.item,
                    parentId: args.parentItemId ?? -1,
                  );
                }
              );
            case '/folder':
              final CreateEditFolderArgs? args = settings.arguments as CreateEditFolderArgs?;
              return MaterialPageRoute(
                builder: (context) {
                  return CreateEditFolder(
                    title: 'Criar Categoria',
                    startFolder: args!.folder,
                    parentId: args.parentItemId ?? -1,
                  );
                }
              );
            case '/takepicture':
              return MaterialPageRoute(
                  builder: (context) => TakePictureScreen(title: 'Editar item')
              );
            default:
              return null;
          }
        },
      ),
    );
  }

}
