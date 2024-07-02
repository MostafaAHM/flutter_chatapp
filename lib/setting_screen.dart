import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class SettingScreen extends StatefulWidget {
  static const String id = 'setting_screen';

  const SettingScreen({Key? key}) : super(key: key);

  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? loggedInUser;
  String? email;
  String? displayName;
  String? photoUrl;
  TextEditingController emailController = TextEditingController();
  TextEditingController displayNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        loggedInUser = user;
        email = user.email;
        displayName = user.displayName;
        photoUrl = user.photoURL;
        emailController.text = email ?? '';
        displayNameController.text = displayName ?? '';
      });
    }
  }

  void updateProfile() async {
    try {
      if (loggedInUser != null) {
        await loggedInUser!.updateEmail(emailController.text);
        await loggedInUser!.updateDisplayName(displayNameController.text);
        await _firestore.collection('users').doc(loggedInUser!.uid).update({
          'email': emailController.text,
          'displayName': displayNameController.text,
        });
        setState(() {
          email = emailController.text;
          displayName = displayNameController.text;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void changePassword(String newPassword) async {
    try {
      await loggedInUser?.updatePassword(newPassword);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image:
                    AssetImage('assets/doddle-4k-lo-fi-x17bthllyfiqv1n0.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Settings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: emailController,
                      style: TextStyle(color: Colors.white), // Text color
                      cursorColor: Colors.white, // Cursor color
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
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
                    SizedBox(height: 20),
                    TextField(
                      controller: displayNameController,
                      style: TextStyle(color: Colors.white), // Text color
                      cursorColor: Colors.white, // Cursor color
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
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
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: updateProfile,
                      child: Text('Update Profile'),
                    ),
                    SizedBox(height: 40),
                    Text(
                      'Account Settings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            String newPassword = '';
                            return AlertDialog(
                              title: Text('Change Password'),
                              content: TextField(
                                onChanged: (value) {
                                  newPassword = value;
                                },
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    changePassword(newPassword);
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('Change'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Text('Change Password'),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _auth.signOut();
                        Navigator.pushNamed(context, LoginScreen.id);
                      },
                      child: Text('Logout'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
