import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

// Function to send a message
Future<void> sendMessage(String sender, String receiver, String message) async {
  final DatabaseReference messagesRef = reference.child('messages');

  await messagesRef.push().set({
    'sender': sender,
    'receiver': receiver,
    'message': message,
    'timestamp': ServerValue.timestamp,
  });
}

// Function to get messages for a conversation
Stream<List<Message>> getMessages(String user1, String user2) {
  final DatabaseReference messagesRef = reference.child('messages');

  return messagesRef
      .orderByChild('timestamp')
      .onValue
      .map((DatabaseEvent event) {
    if (event.snapshot.value == null) {
      print("no messages yet");
      return [];
    } else if (event.snapshot.value is Map<dynamic, dynamic>) {
      Map<String, dynamic> data = Map<String, dynamic>.from(
          event.snapshot.value as Map<String, dynamic>);

      List<Message> messages = data.values
          .where((messageData) =>
              (messageData['sender'] == user1 ||
                  messageData['receiver'] == user1) &&
              (messageData['receiver'] == user2 ||
                  messageData['sender'] == user2))
          .map((messageData) => Message.fromMap(messageData))
          .toList();

      return messages;
    } else {
      // Handle unexpected data type, if needed
      return [];
    }
  });
}

class Message {
  final String sender;
  final String receiver;
  final String message;
  final int timestamp;

  Message({
    required this.sender,
    required this.receiver,
    required this.message,
    required this.timestamp,
  });

  factory Message.fromMap(Map<dynamic, dynamic> map) {
    return Message(
      sender: map['sender'],
      receiver: map['receiver'],
      message: map['message'],
      timestamp: map['timestamp'],
    );
  }
}
