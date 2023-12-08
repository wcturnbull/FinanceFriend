import 'package:financefriend/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class AddFriendsWidget extends StatefulWidget {
  final List<String> userNames;
  final List<String> friendList;
  final Map<String, int> friendStatus;
  final Map<String, String> profilePicUrls;
  final Map<String, String> bios;
  final Function(String) onAddFriend;
  final Function(String) onRemoveFriend;
  final Function(String) onBlock;
  final Function(String) onUnblock;

  const AddFriendsWidget({
    Key? key,
    required this.userNames,
    required this.bios,
    required this.profilePicUrls,
    required this.friendList,
    required this.friendStatus,
    required this.onAddFriend,
    required this.onRemoveFriend,
    required this.onBlock,
    required this.onUnblock,
  }) : super(key: key);

  @override
  _AddFriendsWidgetState createState() => _AddFriendsWidgetState();
}

class _AddFriendsWidgetState extends State<AddFriendsWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      width: 440,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: widget.userNames.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Open a dialog to display user details
                              _showUserProfileDialog(widget.userNames[index]);
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  child: FutureBuilder<String>(
                                    future: getProfilePictureUrl(
                                        widget.userNames[index]),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else {
                                        if (snapshot.hasError) {
                                          // Handle error if necessary
                                          return Icon(Icons.error);
                                        } else {
                                          String imageUrl = snapshot.data ??
                                              ""; // Use an empty string as a fallback
                                          return CircleAvatar(
                                            backgroundImage:
                                                NetworkImage(imageUrl),
                                            radius: 20,
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(widget.userNames[index]),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              child: Text(
                                widget.friendStatus[widget.userNames[index]] ==
                                        2
                                    ? "Unblock"
                                    : "Block",
                              ),
                              onPressed: () {
                                int status;
                                if (widget.friendStatus[
                                        widget.userNames[index]] ==
                                    2) {
                                  widget.onUnblock(widget.userNames[index]);
                                  status = 0;
                                } else {
                                  widget.onBlock(widget.userNames[index]);
                                  widget.friendList
                                      .remove(widget.userNames[index]);
                                  status = 2;
                                }
                                setState(() {
                                  widget.friendStatus[widget.userNames[index]] =
                                      status;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              child: Text(
                                widget.friendStatus[widget.userNames[index]] ==
                                        1
                                    ? "Remove Friend"
                                    : "Add Friend",
                              ),
                              onPressed: () async {
                                int? status = widget
                                    .friendStatus[widget.userNames[index]];
                                if (widget.friendStatus[
                                        widget.userNames[index]] ==
                                    1) {
                                  widget
                                      .onRemoveFriend(widget.userNames[index]);
                                  widget.friendList
                                      .remove(widget.userNames[index]);
                                  status = 0;
                                } else {
                                  if (await widget
                                      .onAddFriend(widget.userNames[index])) {
                                    widget.friendList
                                        .add(widget.userNames[index]);
                                    status = 1;
                                  }
                                }
                                setState(() {
                                  widget.friendStatus[widget.userNames[index]] =
                                      status!;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfileDialog(String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(userName),
          content: Container(
            height: 400, // Set your desired height here
            width: 300, // Set your desired width here
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(
                      widget.profilePicUrls[userName]!,
                    ),
                    radius: 60,
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: <TextSpan>[
                        const TextSpan(
                          text: 'Friend Status: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: widget.friendStatus[userName] == 1
                              ? "Friend"
                              : widget.friendStatus[userName] == 2
                                  ? "Blocked"
                                  : "Not a friend",
                        ),
                      ],
                    ),
                  ), // Add more
                ),
                SizedBox(
                  height: 15,
                ),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: <TextSpan>[
                      const TextSpan(
                        text: 'Bio: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: widget.bios[userName],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
