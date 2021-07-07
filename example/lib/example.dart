import 'dart:io';

import 'package:camera_snap/camera_snap.dart';
import 'package:flutter/material.dart';

class SnapImageExample extends StatefulWidget {
  @override
  _SnapImageExampleState createState() => _SnapImageExampleState();
}

class _SnapImageExampleState extends State<SnapImageExample> {
  File? _image;

  Future getImage() async {
    final imagePath = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraSnapScreen(),
      ),
    );

    setState(() {
      if (imagePath != null) {
        _image = File(imagePath);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Snap Example'),
      ),
      body: Center(child: _buildBody()),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _buildBody() {
    if (_image == null) return Text('No image captured.');

    return Image.file(_image!);
  }
}
