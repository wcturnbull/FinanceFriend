import 'dart:async';

import 'location_card_widget.dart';
import 'package:financefriend/ff_appbar.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

final firebaseApp = Firebase.app();
final database = FirebaseDatabase.instanceFor(
    app: firebaseApp,
    databaseURL: "https://financefriend-41da9-default-rtdb.firebaseio.com/");
final DatabaseReference reference = database.ref();
final userLocationReference =
    reference.child('users/${currentUser?.uid}/locations');
final currentUser = FirebaseAuth.instance.currentUser;
String selectedTimeRange = "All Time";
final DateFormat formatter = DateFormat('yyyy-MM-dd');

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String apiKey = 'AIzaSyC39i7jLqJymR5goAU9ZuTwz4SE4MNXeG8';
  String location = '';
  late Timer _timer;

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
    var response = await http.get(Uri.parse(url));
    var json = jsonDecode(response.body);
    print("response: ${json['result']}");

    List<String> currentTypes = List.from(json['result']['types']);
    final DateTime now = DateTime.now();
    final String formatted = formatter.format(now);

    for (var currentType in currentTypes) {
      if (types.contains(currentType)) {
        userLocationReference
            .child(json['result']['name'] + ':${formatted.toString()}')
            .set(json['result']['formatted_address']);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      getCurrentLocation();
    });

    userLocationReference.onValue.listen((event) {
      DataSnapshot snapshot = event.snapshot;
      var newLocation = snapshot.value.toString();
      setState(() {
        location = newLocation;
      });
    });
  }

  Future<Map> getLocationData() async {
    Map<dynamic, dynamic>? locations = {"No Location Data": ''};
    final DataSnapshot locationSnapshot = await userLocationReference.get();

    if (locationSnapshot.exists) {
      locations = locationSnapshot.value as Map;

      locations.removeWhere((key, value) {
        final now = DateTime.now();
        final locationTime = DateTime.parse(key.toString().split(":")[1]);
        switch (selectedTimeRange) {
          case "1 Day":
            return now.difference(locationTime).inHours > 24;
          case "1 Week":
            return now.difference(locationTime).inDays > 7;
          case "1 Month":
            return now.difference(locationTime).inDays > 30;
          default:
            return false;
        }
      });
    }
    return locations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const FFAppBar(),
        body: Center(
            child: Flex(
                direction: Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
              DropdownButton<String>(
                value: selectedTimeRange,
                items: ["1 Day", "1 Week", "1 Month", "All Time"]
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    selectedTimeRange = value!;
                  });
                },
              ),
              Expanded(
                child: FutureBuilder<Map<dynamic, dynamic>>(
                  future: getLocationData(),
                  builder: (BuildContext context,
                      AsyncSnapshot<Map<dynamic, dynamic>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else {
                      return ListView(
                        children: snapshot.data!.entries.map((entry) {
                          print('entry: $entry');
                          print('entry key: ${entry.key}');
                          print('entry value: ${entry.value}');
                          if (entry.key == "No Location Data") {
                            return Text(entry.key);
                          } else {
                            return LocationCard(
                              locationName: entry.key.toString().split(':')[0],
                              locationAddress: entry.value,
                              date: entry.key.toString().split(':')[1],
                            );
                          }
                        }).toList(),
                      );
                    }
                  },
                ),
              ),
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
