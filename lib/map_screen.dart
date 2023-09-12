import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:routesapp/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:routesapp/main.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Raw coordinates got from  OpenRouteService
  List listOfPoints = [];

  // Conversion of listOfPoints into LatLng(Latitude, Longitude) list of points
  List<LatLng> points = [];

  // List of markers to be added to the map
  // late var myMarkers = ;

  // Marker for the current location
  late Marker currLocMarker = Marker(
    point: _currentPosition == null
        ? const LatLng(0, 0)
        : LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
    width: 80,
    height: 80,
    builder: (context) => IconButton(
      onPressed: () {},
      icon: const Icon(Icons.location_searching),
      color: Colors.blue,
      iconSize: 45,
    ),
  );

  // List of markers for the nearest atm
  List<Marker> atmMarkers = [];

  // Current position of the user
  Position? _currentPosition;

  final mapController = MapController();

  // Method to consume the OpenRouteService API
  getCoordinates() async {
    // Requesting for openrouteservice api
    var response = await http.get(getRouteUrl(
        "1.243344,6.145332", '1.2160116523406839,6.125231015668568'));
    setState(() {
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        listOfPoints = data['features'][0]['geometry']['coordinates'];
        points = listOfPoints
            .map((p) => LatLng(p[1].toDouble(), p[0].toDouble()))
            .toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          zoom: 15,
          center: const LatLng(6.131015, 1.223898),
        ),
        children: [
          // Layer that adds the map
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'dev.fleaflet.flutter_map.example',
          ),
          // Layer that adds points the map
          MarkerLayer(
            markers: [
                  // First Marker
                  // Marker(
                  //   anchorPos: AnchorPos.align(AnchorAlign.top),

                  //   point: LatLng(30.018734, 31.43009),
                  //   // width: 80,
                  //   // height: 80,
                  //   builder: (context) => IconButton(
                  //     onPressed: () {},
                  //     icon: const Icon(Icons.location_on),
                  //     color: Colors.green,
                  //     iconSize: 100,
                  //   ),
                  // ),
                  Marker(
                    point: _currentPosition == null
                        ? const LatLng(0, 0)
                        : LatLng(_currentPosition!.latitude,
                            _currentPosition!.longitude),
                    width: 80,
                    height: 80,
                    builder: (context) => IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.my_location,
                        size: 30,
                      ),
                      color: Colors.blue,
                      iconSize: 45,
                    ),
                  ),
                ] +
                atmMarkers,
          ),

          // Polylines layer
          PolylineLayer(
            polylineCulling: false,
            polylines: [
              Polyline(points: points, color: Colors.black, strokeWidth: 5),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Floating action button to get the user's location
          FloatingActionButton(
            backgroundColor: Colors.blueAccent,
            onPressed: () {
              _getCurrentPosition();
            },
            child: loadingCurrentPos
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Icon(
                    Icons.my_location,
                    color: Colors.white,
                  ),
          ),

          const SizedBox(height: 10),

          // Floating action button to get the route
          FloatingActionButton(
            backgroundColor: Colors.blueAccent,
            onPressed: () => getCoordinates(),
            child: const Icon(
              Icons.route,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 10),

          // Floating action button to get nearest ATM
          FloatingActionButton(
            backgroundColor: Colors.blueAccent,
            onPressed: () => getNearestAtm(),
            child: loadingNearestAtm
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Icon(
                    Icons.atm,
                    color: Colors.white,
                  ),
          ),
        ],
      ),
    );
  }

  var loadingCurrentPos = false;
  Future<void> _getCurrentPosition() async {
    setState(() => loadingCurrentPos = true);
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
      debugPrint(
          'CURRENT POS: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

      // Zooming to the current position
      mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15);
    }).catchError((e) {
      debugPrint(e);
    });
    setState(() => loadingCurrentPos = false);
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  var loadingNearestAtm = false;
  getNearestAtm() async {
    // construct an array of atm lats and long in this format: [[lat1, long1], [lat2, long2], ...]
    List<dynamic> atmLocations = MyApp.allAtms ?? [];
    List<dynamic> userLoc = [
      [_currentPosition!.longitude, _currentPosition!.latitude]
    ];
    var locs = atmLocations.sublist(2294, 2402);
    print(locs);
    print(locs[1]);

    // generate lsit locations where each location is a list of [long, lat] of the atm (long and lat are doubles)
    List<dynamic> locations = [];

    // get type of locs[1][5]
    print(locs[1][5].runtimeType);
    for (var loc in locs) {
      locations.add([loc[5], loc[4]]);
    }

    print("LOCATIONS");
    print(locations);

    setState(() {
      loadingNearestAtm = true;
    });

    // Call the api
    var res = await getDistanceMatrixUrl(userLoc, locations);
    print("RESPONSE");
    print(res);

    setState(() {
      loadingNearestAtm = false;
    });

    var resBody = jsonDecode(res.body);
    print("RESPONSE BODY");
    print(resBody);

    // Get durations
    var leastDuration = resBody['durations'];

    // Get the least distance
    var leastDistance = resBody['distances'];

    // Sources
    var sources = resBody['sources'];

    // pront
    print("Nearest ATM by time is: ");
    print(leastDuration);

    print("Nearest ATM by distance is: ");
    print(leastDistance);

    // Link the leastDistance array with the sources array
    var leastDistanceWithSources = [];
    for (var i = 0; i < leastDistance.length; i++) {
      leastDistanceWithSources.add(
          [leastDistance[i][0], leastDuration[i][0], sources[i]["location"]]);
    }

    print("BEFORE SORTING");
    print(leastDistanceWithSources);
    // Sort the leastDistanceWithSources array
    leastDistanceWithSources.sort((a, b) => a[0].compareTo(b[0]));

    print("\n\n");
    print("AFTER SORTING");
    print(leastDistanceWithSources);

    leastDistanceWithSources = leastDistanceWithSources.sublist(1);

    // Put markers for the first 5 atms in the leastDistanceWithSources array
    List<Marker> myMarkers = [];
    for (var i = 0; i < 5; i++) {
      myMarkers.add(
        Marker(
          anchorPos: AnchorPos.align(AnchorAlign.top),
          point: LatLng(leastDistanceWithSources[i][2][1],
              leastDistanceWithSources[i][2][0]),
          // width: 0,
          // height: 0,
          builder: (ctx) => GestureDetector(
            onTap: () {
              // Show additional information when marker is tapped
              showDialog(
                context: ctx,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Marker Information'),
                    content: const Text(
                        'Additional info here...'), // Add your info here
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
            child: GestureDetector(
              onTap: () {
                print(
                    "Tapped on ATM ${leastDistanceWithSources[i][2][1]}, ${leastDistanceWithSources[i][2][0]}");
              },
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.red[900],
                    size: 45,
                  ),

                  // Info
                  Positioned(
                    top: -37,
                    child: Container(
                      // width: 120,
                      // height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.red[900],
                                    size: 15,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "${leastDistanceWithSources[i][0].toStringAsFixed(0)} m away",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    color: Colors.red[900],
                                    size: 15,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "${(leastDistanceWithSources[i][1] / 60).toStringAsFixed(0)} min away",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Add the markers to the map
    setState(() {
      // myMarkers = myMarkers;
      // myMarkers = myMarkers;
      atmMarkers = myMarkers;
    });
  }
}
