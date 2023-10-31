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
final userLocationReference =
    reference.child('users/${currentUser?.uid}/locations');
final currentUser = FirebaseAuth.instance.currentUser;

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String apiKey = 'AIzaSyC39i7jLqJymR5goAU9ZuTwz4SE4MNXeG8';
  String location = '';

  //Get current location using browser's geolocator
  void getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    getPlaceId(position.latitude, position.longitude);
    print("position: ${position.toString()}");
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
        'https://maps.googleapis.com/maps/api/place/details/json?fields=name%2Ctypes%2Cformatted_address&place_id=$placeId&key=$apiKey';
    print("url: $url");
    var response = await http.get(Uri.parse(url));
    var json = jsonDecode(response.body);
    print("response: ${json['result']}");

    List<String> currentTypes = List.from(json['result']['types']);
    print("types: $currentTypes");
    for (var currentType in currentTypes) {
      if (types.contains(currentType)) {
        storeLocationDetails(
            json['result']['name'], json['result']['formatted_address']);
      }
    }
  }

  void storeLocationDetails(String name, String address) {
    Map<String, String> locationDetails = {
      'address': address,
    };
    userLocationReference.child(name).set(locationDetails);
  }

  @override
  void initState() {
    super.initState();

    userLocationReference.onValue.listen((event) {
      DataSnapshot snapshot = event.snapshot;
      var newLocation = snapshot.value.toString();
      setState(() {
        location = newLocation;
        print(location);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    getCurrentLocation();
    return Scaffold(
        appBar: const FFAppBar(title: 'Location Page'),
        body: Center(
            child: Column(children: [
          ElevatedButton(
            child: Text('Get Current Location'),
            onPressed: () => getCurrentLocation(),
          ),
          Text(location)
        ])));
  }

  final types = [
    "airport",
    "amusement_park",
    "aquarium",
    "art_gallery",
    "atm",
    "bakery",
    "bank",
    "bar",
    "beauty_salon",
    "bicycle_store",
    "book_store",
    "bowling_alley",
    "bus_station",
    "cafe",
    "car_dealer",
    "car_rental",
    "car_repair",
    "car_wash",
    "casino",
    "church",
    "city_hall",
    "clothing_store",
    "convenience_store",
    "courthouse",
    "dentist",
    "department_store",
    "doctor",
    "drugstore",
    "electrician",
    "electronics_store",
    "florist",
    "furniture_store",
    "gas_station",
    "hair_care",
    "health",
    "hardware_store",
    "hindu_temple",
    "home_goods_store",
    "hospital",
    "insurance_agency",
    "jewelry_store",
    "laundry",
    "lawyer",
    "library",
    "light_rail_station",
    "liquor_store",
    "locksmith",
    "lodging",
    "meal_delivery",
    "meal_takeaway",
    "mosque",
    "movie_rental",
    "movie_theater",
    "moving_company",
    "museum",
    "night_club",
    "painter",
    "parking",
    "pet_store",
    "pharmacy",
    "physiotherapist",
    "plumber",
    "police",
    "post_office",
    "primary_school",
    "real_estate_agency",
    "restaurant",
    "roofing_contractor",
    "shoe_store",
    "shopping_mall",
    "spa",
    "stadium",
    "storage",
    "store",
    "subway_station",
    "supermarket",
    "synagogue",
    "taxi_stand",
    "tourist_attraction",
    "train_station",
    "transit_station",
    "travel_agency",
    "veterinary_care",
    "zoo"
  ];
}
