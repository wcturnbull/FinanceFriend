import 'dart:async';
import 'dart:io';

import 'package:financefriend/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:financefriend/social_hub_widgets/friend_helpers.dart';
import 'package:financefriend/social_hub_widgets/user_posts_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class MyUserTile extends StatefulWidget {
  final String name;
  final List<String> goals;
  final Map<String, List<String>> challengeMap;

  MyUserTile({
    Key? key,
    required this.challengeMap,
    required this.name,
    required this.goals,
  }) : super(key: key);

  @override
  _MyUserTileState createState() => _MyUserTileState();
}

class _MyUserTileState extends State<MyUserTile> {
  late String profilePictureUrl;
  late List<String> userChallenges;

  Future<String> fetchChallengesAndProfilePic() async {
    userChallenges = await getChallengesFromName(widget.name);
    profilePictureUrl = await getProfilePictureUrl(widget.name);

    return profilePictureUrl; // Return the profile picture URL
  }

  void createPost() {
    TextEditingController controller = TextEditingController();
    String pic = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            children: <Widget>[
              Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  image: pic.isEmpty
                  ? const DecorationImage(
                    image: AssetImage('images/add-image.png'),
                    fit: BoxFit.cover,
                  ) : DecorationImage(
                    image: FileImage(File(pic)),
                    fit: BoxFit.cover,
                  ),
                ),
                child: pic == ''
                    ? InkWell(
                        onTap: () => pickImage(pic),
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
              onPressed: () {
                // Handle the post submission logic here
                print('Submitted: ${controller.text}');
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> pickImage(String pic) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.gallery);

    if (photo != null) {
      setState(() {
        pic = photo.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      // Specify the type parameter for FutureBuilder
      future: fetchChallengesAndProfilePic(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          String profilePictureUrl = snapshot.data as String? ?? '';
          return ListTile(
            title: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(profilePictureUrl),
                            radius: 20,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            "${widget.name} (you)",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => createPost(),
                        child: const Text("Create Post"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'Goals: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: widget.goals.join(', '),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'Challenges Joined: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: userChallenges.join(', '),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Future<String> getProfilePictureUrl(String name) async {
    String userUID = await getUidFromName(name) ?? '';
    DatabaseEvent event =
        await reference.child('users/$userUID/profilePic').once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value != null) {
      return snapshot.value.toString();
    } else {
      return ''; // Return an empty string if the profile picture URL is not found
    }
  }
}