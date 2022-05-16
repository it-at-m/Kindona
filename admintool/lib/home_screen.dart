import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key, required this.user,}) : super(key: key);

  final User user;

  @override
  Widget build(BuildContext context) {
    
      return Scaffold(
      appBar: AppBar(
        title: const Text('LHM Authentication Demo'),
      ),
      body: Column(
        children: [
          Text(
            "EMail: " + user.email! + " Id: " + user.uid,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SignOutButton(),
        ],
      ),
    );
  }
}
