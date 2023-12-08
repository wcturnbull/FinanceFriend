import 'dart:async';
import 'dart:collection';
import 'dart:html';
import 'dart:js';

import 'package:financefriend/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

DatabaseReference userPostsRef =
    reference.child('users/${currentUser!.uid}/userPosts');
final currentUser = FirebaseAuth.instance.currentUser;
String? user = currentUser?.displayName;

class UserPosts extends StatefulWidget {
  List<Map<String, dynamic>> posts = [];

  UserPosts({super.key});

  @override
  _UserPostsState createState() => _UserPostsState();
}

class _UserPostsState extends State<UserPosts> {
  Future<List<Map<String, dynamic>>> loadUserPosts() async {
    List<Map<String, dynamic>> posts = [];
    String? name = await getUidFromName(user as String);
    DatabaseEvent event = await reference.child('users/$name/posts').once();
    DataSnapshot userposts = event.snapshot;
    Map<String, dynamic>? postList;

      if (userposts.exists) {
        postList = userposts.value as Map<String, dynamic>?;

        for (var uri in postList!.keys) {
          event = await reference.child('users/$name/posts/$uri').once();
          DataSnapshot post = event.snapshot;
          Map<String, dynamic>? postMap = post.value as Map<String, dynamic>?;
          Map<String, dynamic> toAdd = {
            'image': postMap?['image'],
            'text': postMap?['text'],
          };
          posts.add(toAdd);
        }
      } else {
        postList = {'image': '', 'text': 'No Posts Yet'};
        posts.add(postList);
      }
    return posts;
  }

  @override
  void initState() {
    super.initState();
    userPostsRef.onValue.listen((event) {
      setState(() {
        user = event.snapshot.value as String;
        loadUserPosts();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: loadUserPosts(),
      builder: (BuildContext context,
          AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Show a loading spinner while waiting
        } else if (snapshot.hasError) {
          return Text(
              'Error: ${snapshot.error}'); // Show error if something went wrong
        } else {
          return Column(children: [
            Text(
              "${user}'s Posts:",
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            Container(
              height: 500,
              width: 440,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListView(
                children: snapshot.data!.map((entry) {
                  return Column(
                    children: [
                      if (entry['image'] != '') Image.network(entry['image']!),
                      if (entry['text'] != '')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${user}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                )),
                            Text(entry['text']),
                          ],
                        ),
                      const SizedBox(height: 20)
                    ],
                  );
                }).toList(),
              ),
            ),
          ]);
        }
      },
    );
  }
}
