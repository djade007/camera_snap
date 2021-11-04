import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickerExample extends StatefulWidget {
  @override
  _PickerExampleState createState() => _PickerExampleState();
}

class _PickerExampleState extends State<PickerExample> {
  final _picker = ImagePicker();
  File? _image;

  Future getImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    final imagePath = photo?.path;

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
