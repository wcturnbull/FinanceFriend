import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:financefriend/home.dart';

class ProfilePictureUpload extends StatefulWidget {
  String profileUrl;
  final bool dash;

  ProfilePictureUpload(
      {super.key, required this.profileUrl, required this.dash});

  @override
  _ProfilePictureUploadState createState() => _ProfilePictureUploadState();
}

class _ProfilePictureUploadState extends State<ProfilePictureUpload> {
  NetworkImage? _imageFile;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  // New method to load the profile picture
  Future<void> _loadProfilePicture() async {
    // Call getProfilePictureUrl to get the profile picture URL
    String profileUrl =
        await getProfilePictureUrl(currentUser?.displayName ?? '');

    setState(() {
      widget.profileUrl = profileUrl;
      _imageFile = NetworkImage(widget.profileUrl);
    });
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
      await reference.child('users/${currentUser!.uid}/profilePic').set(url);

      setState(() {
        widget.profileUrl = url;
        _imageFile = NetworkImage(widget.profileUrl);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double radius = 50.0;
    if (widget.dash) radius = 100.0;
    return Column(
      children: [
        const SizedBox(height: 16.0),
        _imageFile != null
            ? CircleAvatar(
                radius: radius,
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
        if (!widget.dash)
          ElevatedButton(
            onPressed: _getImage,
            child: const Text('Select Profile Picture'),
          ),
      ],
    );
  }
}
