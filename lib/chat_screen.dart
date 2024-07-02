import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  final String friendUid;

  ChatScreen({required this.friendUid});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late User loggedInUser;
  late TextEditingController messageController;
  final ScrollController _scrollController = ScrollController();
  late Stream<QuerySnapshot> messagesStream;
  late String chatId;
  bool isChatSetup = false;
  String friendEmail = '';
  String friendPhotoUrl = '';

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    messageController = TextEditingController();
    setupChat();
    fetchFriendInfo(); // Fetch friend's information
  }

  void getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        loggedInUser = user;
      });
    }
  }

  void fetchFriendInfo() async {
    DocumentSnapshot friendDoc =
        await _firestore.collection('users').doc(widget.friendUid).get();

    if (friendDoc.exists) {
      setState(() {
        friendEmail = friendDoc['email'];
        friendPhotoUrl = friendDoc['photoUrl'] ?? '';
      });
    }
  }

  void setupChat() async {
    chatId = getChatId(loggedInUser.uid, widget.friendUid);

    DocumentSnapshot chatDoc =
        await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      await _firestore.collection('chats').doc(chatId).set({
        'users': [loggedInUser.uid, widget.friendUid],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      messagesStream = loadMessages();
      isChatSetup = true;
    });

    _scrollToBottom(); // Scroll to bottom after setting up chat
  }

  String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '$uid1\_$uid2' : '$uid2\_$uid1';
  }

  Stream<QuerySnapshot> loadMessages() {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp') // Order by timestamp in ascending order
        .snapshots();
  }

  void sendMessage() {
    String messageText = messageController.text.trim();
    if (messageText.isNotEmpty) {
      _firestore.collection('chats').doc(chatId).collection('messages').add({
        'text': messageText,
        'sender': loggedInUser.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      messageController.clear();
      _scrollToBottom(); // Scroll to bottom after sending message
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
        iconTheme: const IconThemeData(
          color: Colors.white, // Change the color of the back arrow to white
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              backgroundImage: friendPhotoUrl.isNotEmpty
                  ? NetworkImage(friendPhotoUrl)
                  : const AssetImage(
                          'assets/desktop-wallpaper-unknown-abstract-hq-unknown-unknown-person.jpg')
                      as ImageProvider,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                friendEmail,
                style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white), // Ensure the text color is also white
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: <Widget>[
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/a9f61436b34cb0b794d2a0770e434faa.jpg', // Replace with your image asset
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: <Widget>[
              isChatSetup
                  ? Expanded(
                      child: StreamBuilder(
                        stream: messagesStream,
                        builder: (BuildContext context,
                            AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          List<QueryDocumentSnapshot> messages =
                              snapshot.data!.docs.reversed.toList();
                          List<Widget> messageWidgets = [];

                          for (var message in messages) {
                            Map<String, dynamic> data =
                                message.data() as Map<String, dynamic>;
                            String messageText = data['text'];
                            String sender = data['sender'];

                            bool isMe = sender == loggedInUser.uid;

                            Widget messageWidget = Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.all(8.0),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Color.fromARGB(255, 7, 255, 36)
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  messageText,
                                  style: TextStyle(fontSize: 16.0),
                                ),
                              ),
                            );

                            messageWidgets.add(messageWidget);
                          }

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                _scrollController
                                    .position.minScrollExtent, // very important
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          });

                          return ListView(
                            reverse: true,
                            controller: _scrollController,
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            children: messageWidgets,
                          );
                        },
                      ),
                    )
                  : Center(
                      child: CircularProgressIndicator(),
                    ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          hintText: 'Enter your message...',
                          filled: true,
                          fillColor: Colors.white
                              .withOpacity(0.7), // Semi-transparent background
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(12.0)),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: Color.fromARGB(255, 7, 255, 36),
                      ),
                      onPressed: sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
