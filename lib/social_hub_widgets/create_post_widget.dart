import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:financefriend/home.dart';

class CreatePost extends StatefulWidget {
  MemoryImage? _image;
  FilePickerResult? pickedFile;
  Uint8List? bytes;
  String? fileName;

  _CreatePostState createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  Future<void> pickImage() async {
    final file = await FilePicker.platform.pickFiles();

    if (file != null) {
      setState(() {
        widget.bytes = file.files.first.bytes;
        widget.fileName = file.files.first.name;
        widget.pickedFile = file;
        widget._image = MemoryImage(widget.bytes!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();

    return AlertDialog(
      content: Column(
        children: <Widget>[
          Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              image: widget.fileName == null
                  ? const DecorationImage(
                      image: AssetImage('images/add-image.png'),
                      fit: BoxFit.cover,
                    )
                  : DecorationImage(
                      image: widget._image!,
                      fit: BoxFit.cover,
                    ),
            ),
            child: widget.fileName == null
                ? InkWell(
                    onTap: () => pickImage(),
                  )
                : const SizedBox.shrink(),
          ),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Enter your text here',
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Submit'),
          onPressed: () async {

            await FirebaseStorage.instance
                .ref('posts/${widget.fileName}')
                .putData(widget.bytes!);

            var url = await FirebaseStorage.instance
                .ref('posts/${widget.fileName}')
                .getDownloadURL();

            Map<String, String> post = {'image': url, 'text': controller.text};

            reference.child('users/${currentUser!.uid}/posts').push().set(post);

            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
