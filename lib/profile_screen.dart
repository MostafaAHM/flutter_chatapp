import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'login_screen.dart';
import 'chat_screen.dart';
import 'setting_screen.dart'; // Import your HomeScreen here

class ProfileScreen extends StatefulWidget {
  static const String id = 'profile_screen';

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? loggedInUser;
  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> allUsers = [];
  String friendEmail = '';
  TextEditingController _controller = TextEditingController();
  int _selectedIndex = 0; // Set the default selected index to Profile

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    getFriendsList();
    getAllUsers();
    _selectedIndex = 0;
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          loggedInUser = user;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '$uid1\_$uid2' : '$uid2\_$uid1';
  }

  void getFriendsList() async {
    try {
      if (loggedInUser != null) {
        final userDoc =
            await _firestore.collection('users').doc(loggedInUser!.uid).get();
        if (userDoc.exists) {
          List<String> friendUids = List.from(userDoc.data()?['friends'] ?? []);
          List<Map<String, dynamic>> friendDetails = [];

          for (String uid in friendUids) {
            final friendDoc =
                await _firestore.collection('users').doc(uid).get();
            if (friendDoc.exists) {
              // Fetch last message in chat between loggedInUser and friend
              final chatId = getChatId(loggedInUser!.uid, uid);
              final lastMessageSnapshot = await _firestore
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .get();

              String lastMessage = '';
              if (lastMessageSnapshot.docs.isNotEmpty) {
                lastMessage = lastMessageSnapshot.docs.first['text'];
              }

              friendDetails.add({
                'email': friendDoc.data()?['email'],
                'photoUrl': friendDoc.data()?['photoUrl'],
                'uid': uid,
                'lastMessage': lastMessage,
              });
            }
          }

          setState(() {
            friends = friendDetails;
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  void getAllUsers() async {
    try {
      final userDocs = await _firestore.collection('users').get();
      List<Map<String, dynamic>> users = [];
      for (var doc in userDocs.docs) {
        if (doc.id != loggedInUser?.uid) {
          users.add({'email': doc.data()['email'], 'uid': doc.id});
        }
      }
      setState(() {
        allUsers = users;
      });
    } catch (e) {
      print(e);
    }
  }

  void addFriend(String friendUid) async {
    try {
      if (loggedInUser != null) {
        await _firestore.collection('users').doc(loggedInUser!.uid).update({
          'friends': FieldValue.arrayUnion([friendUid])
        });
        getFriendsList();
      }
    } catch (e) {
      print(e);
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the selected screen
    if (index == 1) {
      Navigator.pushNamed(context, SettingScreen.id);
    }
  }

  Widget _buildContent() {
    if (_selectedIndex == 1) {
      return SettingScreen(); // Replace with HomeScreen widget
    } else {
      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(30.0),
            child: TextField(
              controller: _controller, // Use the controller
              onChanged: (value) {
                setState(() {
                  friendEmail = value;
                });
              },
              style: TextStyle(color: Colors.white), // Text color
              cursorColor: Colors.white, // Cursor color
              decoration: InputDecoration(
                labelText: 'Enter friend email',
                labelStyle: TextStyle(color: Colors.white), // Label text color
                suffixIcon: IconButton(
                  icon: Icon(Icons.search,
                      color: Colors.white), // Search icon color
                  onPressed: () {
                    var friend = allUsers.firstWhere(
                      (user) => user['email'] == friendEmail,
                      orElse: () => {},
                    );
                    if (friend.isNotEmpty) {
                      addFriend(friend['uid']);
                      _controller.clear(); // Clear the text field
                    }
                  },
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.white), // Border color when enabled
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.white), // Border color when focused
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                        255, 55, 55, 55), // Example background color
                    borderRadius:
                        BorderRadius.circular(12), // Example border radius
                  ),
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Card(
                    color: Colors.transparent, // Transparent background
                    elevation: 0, // No shadow
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChatScreen(friendUid: friend['uid']),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          maxRadius: 30,
                          backgroundImage: friend['photoUrl'] != null
                              ? NetworkImage(friend['photoUrl'])
                              : AssetImage(
                                  'assets/desktop-wallpaper-unknown-abstract-hq-unknown-unknown-person.jpg'),
                        ),
                        title: Text(
                          friend['email'],
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        subtitle: Text(
                          friend['lastMessage'], // Display last message here
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
        iconTheme: IconThemeData(
          color: Colors.white, // Change the color of the back arrow to white
        ),
        title: Row(
          children: [
            Text(
              'CHAT APP',
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
        // actions: <Widget>[
        //   IconButton(
        //     icon: Icon(Icons.logout),
        //     onPressed: () {
        //       _auth.signOut();
        //       Navigator.pushNamed(context, LoginScreen.id);
        //     },
        //   ),
        // ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/doddle-4k-lo-fi-x17bthllyfiqv1n0.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: _buildContent(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Setting',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        backgroundColor: Color.fromARGB(255, 7, 255, 36),
        onTap: _onItemTapped,
      ),
    );
  }
}
