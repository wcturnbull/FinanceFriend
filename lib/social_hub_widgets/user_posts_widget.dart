import 'dart:async';
import 'dart:collection';
import 'dart:js';

import 'package:financefriend/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserPosts extends StatefulWidget {
  final String user;
  List<Map<String, dynamic>> posts = [];

  UserPosts({super.key, required this.user});

  @override
  _UserPostsState createState() => _UserPostsState();
}

class _UserPostsState extends State<UserPosts> {
  Future<List<Map<String, dynamic>>> loadUserPosts() async {
    List<Map<String, dynamic>> posts = [];
    String? name = await getUidFromName(widget.user);
    DatabaseEvent event = await reference.child('users/$name/posts').once();
    DataSnapshot userposts = event.snapshot;
    Map<String, dynamic>? postList = userposts.value as Map<String, dynamic>?;

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
    return posts;
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
              "${widget.user}'s Posts:",
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
                      Image.network(entry['image']!),
                      if (entry['text'] != '')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${widget.user}: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            )
                          ),
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
