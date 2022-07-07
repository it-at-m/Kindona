import 'package:flutter/material.dart';
import 'package:flutterfire_ui/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'map-view-page2.dart';
import 'map-download-page.dart';
import 'map-file-data.dart';

const mapFileData =  MapFileData(
    url: "https://www.dailyflightbuddy.com/mapsforge_examples/Chemnitz Uni.map",
    fileName: "Chemnitz Uni.map",
    displayedName: "LHM Indoor Map Prototype",
    initialPositionLat: 50.81348,
    initialPositionLong: 12.92936,
    initialZoomLevel: 18,
    indoorZoomOverlay: true,
    indoorLevels: {1: 'OG', 0: 'EG', -1: 'UG'},
  );

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
          title: Text('LHM Map Demo: ' + user.email!),          
        ),
        body: const MapDownloadPage(mapFileData: mapFileData ));              
  }
}
