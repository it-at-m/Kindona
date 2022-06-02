import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('LHM Map Demo'),
        ),
        body: FutureBuilder<MapFile>(
            future: MapFile.from("maps/hamburg.map", null, null),
            builder: (context, AsyncSnapshot<MapFile> snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: [
                    /*FlutterMapView(
              mapModel: mapModel,
              viewModel: viewModel,
              graphicFactory: graphicsFactory),*/
                    Text(
                      "Map: " +
                          snapshot.data!.getMapFileInfo().projectionName! +
                          " EMail: " +
                          user.email! +
                          " Id: " +
                          user.uid,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SignOutButton(),
                  ],
                );
              } else if(snapshot.hasError) {
                return Text("Error: " + snapshot.error.toString());
              } else {
                return CircularProgressIndicator();
              }
            }));
  }
}
