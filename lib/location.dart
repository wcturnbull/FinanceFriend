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
  String apiKey = 'AIzaSyC39i7jLqJymR5goAU9ZuTwz4SE4MNXeG8';

  //Get current location using browser's geolocator
  void getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    getPlaceId(position.latitude, position.longitude);
  }

  //Use Google Place API to get the place id of location
  void getPlaceId(double lat, double lng) async {
    String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';
    var response = await http.get(Uri.parse(url));
    var json = jsonDecode(response.body);
    String placeId = json['results'][0]['place_id'];
    getLocationDetails(placeId);
  }

  //Get the type of location, so the app knows to ask the user to enter expense
  void getLocationDetails(String placeId) async {
    String url =
        'https://maps.googleapis.com/maps/api/place/details/json?fields=name%2Ctypes&place_id=$placeId&key=$apiKey';
    var response = await http.get(Uri.parse(url));
    var json = jsonDecode(response.body);
    //if types correspond to a place where an expense would be made,
    //call a separate function to store location in the database
    List<String> types = List.from(json['results'][0]['types']);

  }

  void storeLocationDetails(String name) {}

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
