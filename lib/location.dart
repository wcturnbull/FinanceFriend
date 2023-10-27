import 'package:financefriend/ff_appbar.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final currentUser = FirebaseAuth.instance.currentUser;

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  void getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    storeLocationDetails(position.latitude, position.longitude);
  }

  void storeLocationDetails(double lat, double lng) async {
    String apiKey = 'AIzaSyDu2xvfCsKkP85kqcC0g6RDW-31P-_ygMs';
    String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&key=$apiKey';
    var response = await http.get(Uri.parse(url));
    var json = jsonDecode(response.body);
    for (var place in json['results']) {
      print(place);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const FFAppBar(title: 'Location Page'),
        body: Center(
          child: ElevatedButton(
              onPressed: () => getCurrentLocation(),
              child: const Text('Get Current Location')),
        ));
  }
}
