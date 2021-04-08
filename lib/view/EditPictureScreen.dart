import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_crop/image_crop.dart';

class EditPictureScreen extends StatefulWidget {

  final imagePath;

  const EditPictureScreen(this.imagePath, {Key? key}) : super(key: key);

  @override
  EditPictureScreenState createState() => EditPictureScreenState();
}

class EditPictureScreenState extends State<EditPictureScreen> {

  final cropKey = GlobalKey<CropState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Expanded(
        child: Crop.file(
          File(widget.imagePath),
          key: cropKey,
        ),
      ),
      bottomNavigationBar: Container(
        height: 60.0,
        child: ElevatedButton.icon(
          icon: Icon(Icons.crop),
          label: Text("Cortar foto"),
          onPressed: _cropImage,
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

  Future<void> _cropImage() async {
    final scale = cropKey.currentState!.scale;
    final area = cropKey.currentState!.area;

    if (area == null) return;

    final sample = await ImageCrop.sampleImage(
      file: File(widget.imagePath),
      preferredSize: (2000 / scale).round(),
    );

    final file = await ImageCrop.cropImage(
      file: sample,
      area: area,
    );

    sample.delete();

    Navigator.of(context).pop(file.path);
  }

}