import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class ProfilePictureUpload extends StatefulWidget {
  String profileUrl;

  ProfilePictureUpload({
    super.key,
    required this.profileUrl,
  });

  @override
  _ProfilePictureUploadState createState() => _ProfilePictureUploadState();
}

class _ProfilePictureUploadState extends State<ProfilePictureUpload> {
  NetworkImage? _imageFile;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _imageFile = NetworkImage(widget.profileUrl);
  }

  Future<void> _getImage() async {
    final pickedFile = await FilePicker.platform.pickFiles();

    if (pickedFile != null) {
      Uint8List? fileBytes = pickedFile.files.first.bytes;
      String fileName = pickedFile.files.first.name;

      await FirebaseStorage.instance
          .ref('profile_pictures/$fileName')
          .putData(fileBytes!);

      final url = await FirebaseStorage.instance
          .ref('profile_pictures/$fileName')
          .getDownloadURL();

      await currentUser?.updatePhotoURL(url);

      widget.profileUrl = url;

      setState(() {
        _imageFile = NetworkImage(widget.profileUrl);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16.0),
        _imageFile != null
            ? CircleAvatar(
                radius: 50.0,
                backgroundImage: _imageFile!,
              )
            : const CircleAvatar(
                radius: 50.0,
                backgroundColor: Colors.grey,
                child: Icon(
                  Icons.person,
                  size: 60.0,
                  color: Colors.white,
                ),
              ),
        const SizedBox(height: 10.0),
        ElevatedButton(
          onPressed: _getImage,
          child: const Text('Select Profile Picture'),
        ),
      ],
    );
  }
}
