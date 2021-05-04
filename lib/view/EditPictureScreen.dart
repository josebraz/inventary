import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_crop/image_crop.dart';

class EditPictureScreen extends StatefulWidget {

  final imagePath;

  EditPictureScreen(this.imagePath, {Key? key}) : super(key: key);

  @override
  EditPictureScreenState createState() => EditPictureScreenState();
}

class EditPictureScreenState extends State<EditPictureScreen> {

  final cropKey = GlobalKey<CropState>();

  late Future<bool> _permissionsGranted;

  @override
  void initState() {
    super.initState();
    _permissionsGranted = ImageCrop.requestPermissions();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _permissionsGranted,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.requireData) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            extendBodyBehindAppBar: true,
            body: (!snapshot.hasData)
                ? Center(child: CircularProgressIndicator())
                : Center(
                    child: Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Permissões não garantidas",
                            style: TextStyle(
                              fontSize: 17.0,
                            ),
                          ),
                          SizedBox(
                            height: 20.0,
                          ),
                          ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop(widget.imagePath);
                              },
                              child: Text(
                                "Voltar",
                                style: TextStyle(
                                  fontSize: 17.0,
                                ),
                              )
                          )
                        ],
                      ),
                    ),
                  )

          );
        } else {
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
      }
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