import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:routesapp/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var res = await loadCsv();
  print(res.length);
  print(res);
  MyApp.allAtms = res;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static List<dynamic>? allAtms;

  static dynamic keys = {
    "Id": 0,
    "Governate": 1,
    "Area Name": 2,
    "ATM Name": 3,
    "Latitude": 4,
    "Longitude": 5,
    "Description": 6
  }

      // "Governate": 1;"Area": 1 "Name": 1;"ATM": 1; "Name","Latitude","Longitude","Description"}

      ;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}

// method to load csv to list
Future<List<List<dynamic>>> loadCsv() async {
  final myData = await rootBundle.loadString("assets/all_atms_processed.csv");
  List<List<dynamic>> csvTable = const CsvToListConverter().convert(myData);
  return csvTable;
}
