import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/bloc/ItemBloc.dart';
import 'package:inventary/model/ItemEntity.dart';
import 'package:inventary/extensions/StateExtension.dart';

class CreateEditFolderArgs {
  final ItemEntity? parentItem;
  final ItemEntity? folder;

  CreateEditFolderArgs({this.parentItem, this.folder});
}

class CreateEditFolder extends StatefulWidget {
  CreateEditFolder({Key? key, required this.title, required this.startFolder}) : super(key: key);

  final String title;
  final ItemEntity startFolder;

  @override
  _CreateEditFolderState createState() => _CreateEditFolderState(startFolder);
}

class _CreateEditFolderState extends State<CreateEditFolder> {
  final _formKey = GlobalKey<FormState>();

  late ItemEntity _item;

  _CreateEditFolderState(ItemEntity startFolder) {
    this._item = startFolder;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: _buildForm(),
        ),
        bottomNavigationBar: Container(
          height: 60.0,
          child: ElevatedButton.icon(
            icon: Icon(Icons.save),
            label: Text(
              "Salvar",
              style: TextStyle(
                fontSize: 18.0,
              ),
            ),
            onPressed: _save,
            style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0.0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            TextFormField(
              initialValue: _item.name,
              keyboardType: TextInputType.name,
              minLines: 1,
              maxLines: 1,
              decoration: const InputDecoration(
                icon: Icon(Icons.drive_file_rename_outline),
                hintText: 'Qual nome da nova Categoria?',
                labelText: 'Nome *',
              ),
              validator: (String? value) {
                return (value != null && value.isEmpty)
                    ? 'Preencha o campo de nome'
                    : null;
              },
              onSaved: (String? value) {
                _item.name = value ?? "";
              },
            ),
            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  void _save() {
    final form = _formKey.currentState!;
    if (form.validate()) {
      form.save();
      BlocProvider.of<ItemBloc>(context).insert(_item).then((value) {
        showSnack('Categoria salva com sucesso');
        Navigator.of(context).pop();
      }).catchError((error) {
        print('error in inset item $error');
        showSnack('Erro ao salvar Categoria');
      });
    }
  }
}