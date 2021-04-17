import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventary/bloc/ItemBloc.dart';
import 'package:inventary/model/ItemEntity.dart';
import 'package:inventary/extensions/StateExtension.dart';

class CreateEditItemArgs {
  final ItemEntity? parentItem;
  final ItemEntity? item;

  CreateEditItemArgs({this.parentItem, this.item});
}

class CreateEditItemScreen extends StatefulWidget {
  CreateEditItemScreen({Key? key, required this.title, required this.startItem})
      : super(key: key);

  final String title;
  final ItemEntity startItem;

  @override
  _CreateEditItemScreenState createState() => _CreateEditItemScreenState(startItem);
}

class _CreateEditItemScreenState extends State<CreateEditItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late List<String?> _imagesList;
  late ItemEntity _item;

  _CreateEditItemScreenState(ItemEntity startItem) {
    this._item = startItem;
    this._imagesList = _item.attachmentsPath.map((e) => e).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildForm(context),
      bottomNavigationBar: Container(
        height: 60.0,
        child: ElevatedButton.icon(
          icon: Icon(Icons.save),
          label: Text("Salvar"),
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
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              height: 274.0,
              width: double.infinity,
              child: Stack(
                children: [
                  _buildItemImage(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 15.0),
                      child: FloatingActionButton(
                        heroTag: "take_picture",
                        onPressed: () {
                          _pictureOptions(context);
                        },
                        tooltip: "Tirar foto",
                        elevation: 5.0,
                        child: Icon(Icons.add_a_photo),
                      ),
                    )
                  )
                ],
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemImage() {
    if (_imagesList.isEmpty) {
      return Hero(
        tag: "item_picture_${_item.id}",
        child: Image.asset(
          "assets/images.png",
          fit: BoxFit.fitWidth,
          height: 250,
          width: double.infinity,
        )
      );
    } else {
      return Hero(
        tag: "item_picture_${_item.id}",
        child: Image.file(
          File(_imagesList.first!),
          fit: BoxFit.fitWidth,
          height: 250,
          width: double.infinity,
        ),
      );
    }
  }

  void _takePicture() async {
    var imagePath = await Navigator.of(context).pushNamed('/takepicture') as String?;
    if (imagePath != null) {
      setState(() {
        _imagesList = [imagePath];
      });
    }
  }

  void _selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'gif'],
    );
    if(result != null) {
      setState(() {
        _imagesList = [result.files.single.path];
      });
    }
  }

  void _pictureOptions(BuildContext context){
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
          child: new Wrap(
            children: <Widget>[
              new ListTile(
                  leading: new Icon(Icons.file_upload),
                  title: new Text('Selecionar arquivo'),
                  onTap: _selectFile
              ),
              new ListTile(
                leading: new Icon(Icons.camera_alt_rounded),
                title: new Text('Tirar foto'),
                onTap: _takePicture,
              ),
            ],
          ),
        );
      }
    );
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
