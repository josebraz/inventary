import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/bloc/ItemBloc.dart';
import 'package:inventary/model/ItemEntity.dart';
import 'package:inventary/extensions/StateExtension.dart';

class CreateEditItemArgs {
  final int? parentItemId;
  final ItemEntity? item;

  CreateEditItemArgs({this.parentItemId, this.item});
}

class CreateEditItem extends StatefulWidget {
  CreateEditItem({Key? key, required this.title, required this.startItem})
      : super(key: key);

  final String title;
  final ItemEntity startItem;

  @override
  _CreateEditItemState createState() => _CreateEditItemState(startItem);
}

class _CreateEditItemState extends State<CreateEditItem> {
  final _formKey = GlobalKey<FormState>();

  late List<String?> _imagesList;
  late ItemEntity _item;

  _CreateEditItemState(ItemEntity startItem) {
    this._item = startItem;
    this._imagesList = _item.attachmentsPath.map((e) => e).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: _buildForm(),
      ),
      bottomNavigationBar: Container(
        height: 50.0,
        child: ElevatedButton.icon(
          icon: Icon(Icons.save),
          label: Text((_item.id == null) ? "Salvar novo item" : "Salvar alterações"),
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
      floatingActionButton: FloatingActionButton(
        heroTag: "take_picture",
        onPressed: _takePicture,
        tooltip: "Tirar foto",
        child: Icon(Icons.add_a_photo),
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
              validator: (String? value) {
                return (value != null && value.isEmpty)
                    ? 'Preencha o campo de nome'
                    : null;
              },
              onSaved: (String? value) {
                _item.name = value ?? "";
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
              validator: (String? value) {
                return null;
              },
              onSaved: (String? value) {
                _item.description = value ?? "";
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
              validator: (String? value) {
                return null;
              },
              onSaved: (String? value) {
                _item.location = value ?? "";
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
              validator: (String? value) {
                return null;
              },
              onSaved: (String? value) {
                _item.loan = value ?? "";
              },
            ),
            SizedBox(height: 5),
            if (_imagesList.length > 0) Image.file(File(_imagesList.first!)),
          ],
        ),
      ),
    );
  }

  void _takePicture() async {
    var imagePath = await Navigator.of(context).pushNamed('/takepicture');
    setState(() {
      _imagesList.add(imagePath as String?);
    });
  }

  void _save() {
    final form = _formKey.currentState!;
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
