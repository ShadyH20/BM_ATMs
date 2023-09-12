import 'dart:convert';

import 'package:http/http.dart' as http;

/// OPENROUTESERVICE DIRECTION SERVICE REQUEST
/// Parameters are : startPoint, endPoint and api key

const String baseUrl =
    'https://api.openrouteservice.org/v2/directions/driving-car';
const String apiKey =
    '5b3ce3597851110001cf6248f55d7a31499e40848c6848d7de8fa624';

getRouteUrl(String startPoint, String endPoint) {
  return Uri.parse('$baseUrl?api_key=$apiKey&start=$startPoint&end=$endPoint');
}

getDistanceMatrixUrl(dynamic userLocation, List<dynamic> atmLocations) {
  List<dynamic> locations = userLocation;
  locations.addAll(atmLocations);
  // locations.add([6.125231015668568, 1.2160116523406839]);

  var body = {
    "locations": locations,
    "destinations": [0],
    "metrics": ["distance", "duration"]
  };

  print("REQUEST BODY");
  print(body);

  const headers = {
    'Accept':
        'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
    'Authorization': '5b3ce3597851110001cf6248f55d7a31499e40848c6848d7de8fa624',
    'Content-Type': 'application/json; charset=utf-8'
  };

  // post request
  return http.post(
      Uri.parse("https://api.openrouteservice.org/v2/matrix/driving-car"),
      headers: headers,
      body: jsonEncode(body));
}
