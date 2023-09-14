import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:routesapp/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var res = await loadCsvs();
  MyApp.allAtms = res[0];
  MyApp.depAtms = res[1];
  MyApp.exAtms = res[2];
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static List<dynamic>? allAtms;
  static List<dynamic>? depAtms;
  static List<dynamic>? exAtms;

  static dynamic keys = {
    "Id": 0,
    "Governate": 1,
    "Area Name": 2,
    "ATM Name": 3,
    "Latitude": 4,
    "Longitude": 5,
    "Description": 6
  };

  // MaterialApp(
//             builder: (context, child) {
//               return MediaQuery(
//                 data: MediaQuery.of(context).copyWith(
//                   textScaleFactor: 1.0,
//                 ),
//                 child: child!,
//               );
//             },

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0,
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}

// method to load csv to list
loadCsvs() async {
  final myData = await rootBundle.loadString("assets/all_atms_processed.csv");
  final myDataDep =
      await rootBundle.loadString("assets/all_atms_processed_deposit.csv");
  final myDataEx =
      await rootBundle.loadString("assets/all_atms_processed_exchange.csv");
  List<List<dynamic>> csvTable = const CsvToListConverter().convert(myData);
  List<List<dynamic>> csvTableDep =
      const CsvToListConverter().convert(myDataDep);
  List<List<dynamic>> csvTableEx = const CsvToListConverter().convert(myDataEx);

  return [csvTable, csvTableDep, csvTableEx];
}
