import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/bloc/ItemBloc.dart';
import 'package:inventary/model/ItemEntity.dart';
import 'package:inventary/extensions/StateExtension.dart';

class CreateEditItemArgs {
  final int parentItemId;
  final ItemEntity item;

  CreateEditItemArgs({this.parentItemId, this.item});
}

class CreateEditItem extends StatefulWidget {
  CreateEditItem({Key key, this.title, this.startItem, this.parentId = -1}) : super(key: key);

  final String title;
  final int parentId;
  final ItemEntity startItem;

  @override
  _CreateEditItemState createState() => _CreateEditItemState(startItem, parentId);
}

class _CreateEditItemState extends State<CreateEditItem> {
  final _formKey = GlobalKey<FormState>();

  List<String> _imagesList;
  ItemEntity _item;

  _CreateEditItemState(ItemEntity startItem, int parentId) {
    this._item = startItem ?? ItemEntity(isFolder: false, parent: parentId);
    this._imagesList = _item.attachmentsPath.map((e) => e).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Salvar',
            onPressed: _save,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: _buildForm(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        tooltip: "Tirar foto",
        child: Icon(Icons.camera_alt),
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
                hintText: 'Qual nome do novo Item?',
                labelText: 'Nome *',
              ),
              validator: (String value) {
                return (value != null && value.isEmpty)
                    ? 'Preencha o campo de nome'
                    : null;
              },
              onSaved: (String value) {
                _item.name = value;
              },
            ),
            SizedBox(height: 5),
            TextFormField(
              initialValue: _item.description,
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: 5,
              decoration: const InputDecoration(
                icon: Icon(Icons.description),
                hintText: 'Qual descrição do novo Item?',
                labelText: 'Descrição (opcional)',
              ),
              validator: (String value) {
                return null;
              },
              onSaved: (String value) {
                _item.description = value;
              },
            ),
            SizedBox(height: 5),
            TextFormField(
              initialValue: _item.location,
              keyboardType: TextInputType.text,
              minLines: 1,
              maxLines: 1,
              decoration: const InputDecoration(
                icon: Icon(Icons.my_location_sharp),
                hintText: 'Qual localização do novo Item?',
                labelText: 'Localização (opcional)',
              ),
              validator: (String value) {
                return null;
              },
              onSaved: (String value) {
                _item.location = value;
              },
            ),
            SizedBox(height: 5),
            TextFormField(
              initialValue: _item.loan,
              keyboardType: TextInputType.text,
              minLines: 1,
              maxLines: 1,
              decoration: const InputDecoration(
                icon: Icon(Icons.supervised_user_circle_sharp),
                hintText: 'O item está emprestado para alguém?',
                labelText: 'Emprestado para (opcional)',
              ),
              validator: (String value) {
                return null;
              },
              onSaved: (String value) {
                _item.loan = value;
              },
            ),
            SizedBox(height: 5),
            if (_imagesList.length > 0) Image.file(File(_imagesList.first)),
            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  void _takePicture() async {
    var imagePath = await Navigator.of(context).pushNamed('/takepicture');
    setState(() {
      _imagesList.add(imagePath);
    });
  }

  void _save() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      _item.attachmentsPath = _imagesList;
      BlocProvider.of<ItemBloc>(context).insert(_item).then((value) {
        showSnack('Item salvo com sucesso');
        Navigator.of(context).pop();
      }).catchError((error) {
        print('error in inset item $error');
        showSnack('Erro ao salvar Item');
      });
    }
  }

}