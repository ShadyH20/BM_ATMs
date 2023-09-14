import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:multi_select_flutter/chip_field/multi_select_chip_field.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:routesapp/api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:routesapp/main.dart';
import 'package:url_launcher/url_launcher.dart';

Color bmYellow = const Color(0xffe5aa00);
Color bmRed = const Color(0xff871e35);

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

  // Store service type
  List<dynamic> selectedServices = ["withdrawal"];

  List<MultiSelectItem<Object?>> items = [
    MultiSelectItem("withdrawal", "Withdrawal"),
    MultiSelectItem("deposit", "Deposit"),
    MultiSelectItem("currency_exchange", "Currency Exchange"),
  ];

  chipLabel(MultiSelectItem item) => Row(
      children: <Widget>[
            Text(item.label.toString(),
                style: TextStyle(
                    color: selectedServices.contains(item.value)
                        ? Colors.white
                        : Colors.black)),
          ] +
          (selectedServices.contains(item.value)
              ? const <Widget>[
                  SizedBox(width: 2),
                  Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.white,
                  )
                ]
              : []));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ATM Locator"),
        backgroundColor: bmRed,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Container containing a choice chip to select the type of service the user wants from: withdrawal, deposit, and currency exchange

          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              zoom: 15,
              center: const LatLng(30.0188, 31.4293),
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

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              width: MediaQuery.of(context).size.width,
              // color: Colors.grey[200],
              // Blurred background
              decoration: BoxDecoration(
                // white bottom border
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.9),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.9),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // TEXT
                  const Text(
                    "Select the type of service you want",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: MultiSelectChipField(
                  //     items: items,
                  //     onTap: (values) {
                  //       selectedServices = values;
                  //     },
                  //     initialValue: const ['withdrawal'],
                  //     textStyle: const TextStyle(
                  //       color: Colors.black,
                  //       fontSize: 13,
                  //     ),
                  //     selectedTextStyle: const TextStyle(
                  //       // color: Colors.white,
                  //       fontSize: 18,
                  //     ),
                  //     selectedChipColor: bmYellow,
                  //     // chipWidth: MediaQuery.of(context).size.width * 0.,
                  //     decoration: BoxDecoration(
                  //       color: Colors.grey,
                  //       border: Border.all(
                  //         color: Colors.transparent,
                  //       ),
                  //     ),
                  //     showHeader: false,
                  //     title: const Text("Services"),
                  //   ),
                  // ),
                  const SizedBox(height: 8),

                  // CHIPS
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    spacing: 5,

                    // alignment: WrapAlignment.spaceEvenly,
                    // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FittedBox(
                        child: ChoiceChip(
                          label: chipLabel(items[0]),
                          selected: selectedServices.contains('withdrawal'),
                          shape: const StadiumBorder(
                            side: BorderSide(color: Colors.black54),
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: bmYellow,
                          onSelected: (bool selected) {
                            setState(() {
                              if (!selected) {
                                selectedServices.remove('withdrawal');
                              } else {
                                selectedServices.add('withdrawal');
                              }
                            });
                          },
                        ),
                      ),
                      FittedBox(
                        child: ChoiceChip(
                          label: chipLabel(items[1]),
                          selected: selectedServices.contains('deposit'),
                          shape: const StadiumBorder(
                            side: BorderSide(color: Colors.black54),
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: bmYellow,
                          onSelected: (bool selected) {
                            setState(() {
                              if (!selected) {
                                selectedServices.remove('deposit');
                              } else {
                                selectedServices.add('deposit');
                              }
                            });
                          },
                        ),
                      ),
                      FittedBox(
                        child: ChoiceChip(
                          label: chipLabel(items[2]),
                          selected:
                              selectedServices.contains('currency_exchange'),
                          shape: const StadiumBorder(
                            side: BorderSide(color: Colors.black54),
                          ),
                          backgroundColor: Colors.white,
                          selectedColor: bmYellow,
                          onSelected: (bool selected) {
                            setState(() {
                              if (!selected) {
                                selectedServices.remove('currency_exchange');
                              } else {
                                selectedServices.add('currency_exchange');
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // SEARCH BUTTON
                  ElevatedButton(
                    onPressed: () {
                      // Call the api
                      getNearestAtm();
                    },
                    style: ElevatedButton.styleFrom(
                      primary: bmYellow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: loadingNearestAtm
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ))
                        : const Text("Search", style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Floating action button to show next atm info
          FloatingActionButton(
              backgroundColor: bmRed,
              onPressed: () {
                setState(() {
                  focused = focused == 4 ? 0 : focused + 1;
                });
              },
              child: const Text("Next", style: TextStyle(fontSize: 10))),
          SizedBox(height: 10),

          // Floating action button to get google maps directions
          FloatingActionButton(
            backgroundColor: bmRed,
            onPressed: () async {
              if (focused == -1) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Please search for the nearest atm before getting directions'),
                    backgroundColor: Color(0xff2e2e2e)));
                return;
              }
              // redirect to google maps with directiona to the atm location
              final Uri url = Uri.parse(
                  "https://www.google.com/maps/dir/?api=1&origin=${_currentPosition!.latitude},${_currentPosition!.longitude}&destination=${atmMarkers[focused].point.latitude},${atmMarkers[focused].point.longitude}&travelmode=driving");
              // redirect
              if (!await launchUrl(url)) {
                throw Exception('Could not launch $url');
              }
            },
            child: const Icon(
              Icons.directions,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          // Floating action button to get the user's location
          FloatingActionButton(
            backgroundColor: bmRed,
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

  int focused = -1;

  var loadingNearestAtm = false;
  getNearestAtm() async {
    // Check if the user has selected a service
    if (selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a service to search for'),
          backgroundColor: Color(0xff2e2e2e)));
      return;
    }

    // construct an array of atm lats and long in this format: [[lat1, long1], [lat2, long2], ...]
    List<dynamic> atmLocations = selectedServices.contains("currency_exchange")
        ? MyApp.exAtms!
        : selectedServices.contains("deposit")
            ? MyApp.depAtms!
            : MyApp.allAtms!;

    List<dynamic> userLoc = [
      [_currentPosition!.longitude, _currentPosition!.latitude]
    ];

    // DEPOSIT [450->805]
    //  CURRENCY EXCHANGE [393->743]
    // var locs = atmLocations.sublist(2294, 2402);
    var locs = selectedServices.contains("currency_exchange")
        ? atmLocations.sublist(392, 744)
        : selectedServices.contains("deposit")
            ? atmLocations.sublist(451, 806)
            : atmLocations.sublist(2294, 2402);

    // print(locs);
    // print(locs[1]);

    // generate lsit locations where each location is a list of [long, lat] of the atm (long and lat are doubles)
    List<dynamic> locations = [];

    // get type of locs[1][5]
    // print(locs[1][5].runtimeType);
    for (var loc in locs) {
      locations.add([loc[5], loc[4]]);
    }

    // print("LOCATIONS");
    // print(locations);

    setState(() {
      loadingNearestAtm = true;
    });

    // Call the api
    var res = await getDistanceMatrixUrl(userLoc, locations);
    // print("RESPONSE");
    // print(res);

    setState(() {
      loadingNearestAtm = false;
    });

    var resBody = jsonDecode(res.body);
    // print("RESPONSE BODY");
    // print(resBody);

    // Get durations
    var leastDuration = resBody['durations'];

    // Get the least distance
    var leastDistance = resBody['distances'];

    // Sources
    var sources = resBody['sources'];

    // pront
    // print("Nearest ATM by time is: ");
    // print(leastDuration);

    // print("Nearest ATM by distance is: ");
    // print(leastDistance);

    // Link the leastDistance array with the sources array
    var leastDistanceWithSources = [];
    for (var i = 0; i < leastDistance.length; i++) {
      leastDistanceWithSources.add(
          [leastDistance[i][0], leastDuration[i][0], sources[i]["location"]]);
    }

    // print("BEFORE SORTING");
    // print(leastDistanceWithSources);
    // Sort the leastDistanceWithSources array
    leastDistanceWithSources.sort((a, b) => a[0].compareTo(b[0]));

    // print("\n\n");
    // print("AFTER SORTING");
    // print(leastDistanceWithSources);

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

          builder: (ctx) => Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedScale(
                alignment: Alignment.bottomRight,
                duration: const Duration(milliseconds: 300),
                scale: focused == i ? 1.15 : 1,
                child: Icon(
                  Icons.location_on,
                  color: bmRed,
                  size: 45,
                ),
              ),

              // Info
              focused == i
                  ? Positioned(
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
                                      color: bmRed,
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
                                      color: bmRed,
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
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      );
    }

    // Move the map so that it contains all the 5 markers
    mapController.fitBounds(
        LatLngBounds.fromPoints(myMarkers.map((e) => e.point).toList()),
        options: FitBoundsOptions(
          padding: EdgeInsets.all(50),
        ));

    // Add the markers to the map
    setState(() {
      // myMarkers = myMarkers;
      // myMarkers = myMarkers;
      atmMarkers = myMarkers;
    });
  }
}
