import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';


class TakePictureScreen extends StatefulWidget {
  final String? title;

  const TakePictureScreen({
    Key? key,
    this.title,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = availableCameras().then((cameras) {
      final camera = cameras[0];
      _controller = CameraController(camera, ResolutionPreset.max);
      return _controller.initialize();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final size = MediaQuery.of(context).size;
            final deviceRatio = size.width / size.height;
            return Container(
              color: Colors.black,
              child: Center(
                child: Transform.scale(
                  scale: deviceRatio * 2,
                  child: CameraPreview(_controller),
                ),
              ),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      bottomNavigationBar: Container(
        height: 60.0,
        child: ElevatedButton.icon(
          icon: Icon(Icons.camera_alt),
          label: Text("Tirar foto"),
          onPressed: _takePicture,
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

  void _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      Navigator.of(context).pop(image.path);
    } catch (e) {
      print(e);
    }
  }

}