import 'dart:convert';

import 'package:basic_utils/basic_utils.dart';
import 'package:http/http.dart' as http;

/// A wrapper for the NHTSA REST API
/// Ex: https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVin/WP0ZZZ99ZTS392124?format=json
/// Docs: https://vpic.nhtsa.dot.gov/api/
class NHTSA {
  static const String _uriBase = 'https://vpic.nhtsa.dot.gov/api/vehicles';

  /// NHTSA Results not relevant for a specific vehicle can be either null or N/A
  static const String resultNotApplicable = 'Not Applicable';

  /// Obtain information about a given [vin] from the NHTSA DB.
  static Future<NHTSAVehicleInfo?> decodeVin(String vin) async {
    var path = '$_uriBase/DecodeVin/$vin?format=json';
    final response = await http.get(Uri.parse(path));

    if (response.statusCode == 200) {
      return NHTSAVehicleInfo.fromJson(jsonDecode(response.body));
    }

    return null;
  }

  /// Obtain a map of key/value pairs containing known values for a given [vin]
  static Future<Map<String, dynamic>?> decodeVinValues(String vin) async {
    var path = '$_uriBase/DecodeVinValues/$vin?format=json';
    final response = await http.get(Uri.parse(path));

    // The DecodeVinValues endpoint returns a single Results object with all
    // variables and values as an array of encapsulated key/value pairs.
    // Manually unpack this in order to provide the caller a populated Dart map.
    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      Map<String, dynamic> map = data['Results'][0];
      // Discard empty and not applicable entries from map
      map.removeWhere((key, value) =>
          value == null || value == resultNotApplicable || value == '');
      return map;
    }

    return null;
  }

  /// Returns a list of all makes from the NHTSA DB.
  /// https://vpic.nhtsa.dot.gov/api/vehicles/getallmakes?format=json
  static Future<List<String>?> getAllMakes() async {
    var path = '$_uriBase/getallmakes?format=json';
    final response = await http.get(Uri.parse(path));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);
      final results = data['Results'];
      final makes = <String>[];
      if (results is List) {
        for (final element in results) {
          final make = element['Make_Name'] as String?;
          if (make != null && make.isNotEmpty) {
            makes.add(make);
          }
        }
      }
      return makes;
    }

    return null;
  }

  List<String>? _makes;

  Future<bool> isMakeValid(String make) async {
    _makes ??= await getAllMakes();
    final valid = _makes?.contains(make.toUpperCase()) ?? false;
    return valid;
  }
}

/// The result of a single data point from the NHTSA DB for a specific variable.
class NHTSAResult {
  /// The value associated with a given [variable] or [variableId]
  String value;

  /// The ID number associated with a given [value]
  String valueId;

  /// The variable name
  String variable;

  /// The ID number of a given [variable]
  int variableId;

  NHTSAResult(
      {required this.value,
      required this.valueId,
      required this.variable,
      required this.variableId});

  /// Create a new [NHTSAResult] instance from a fixed JSON payload
  factory NHTSAResult.fromJson(Map<String, dynamic> json) => NHTSAResult(
        value: json['Value'] ?? '',
        valueId: json['ValueId'],
        variable: json['Variable'],
        variableId: json['VariableId'],
      );

  @override
  String toString() {
    return 'NHTSAResult[value=$value, valueId=$valueId, variable=$variable, variableId=$variableId]';
  }
}

/// Extended vehicle information for a specific VIN obtained from the NHTSA DB.
class NHTSAVehicleInfo {
  int count;
  String message;
  String searchCriteria;
  List<NHTSAResult> results = [];

  NHTSAVehicleInfo(
      {required this.count,
      required this.message,
      required this.searchCriteria,
      required this.results});

  /// Create a new [NHTSAVehicleInfo] instance from a fixed JSON payload
  factory NHTSAVehicleInfo.fromJson(Map<String, dynamic> json) {
    final results = <NHTSAResult>[];
    if (json['Results'] != null) {
      json['Results'].forEach((v) {
        if (v['Value'] != null &&
            v['Value'] != NHTSA.resultNotApplicable &&
            v['Value'] != '') {
          results.add(NHTSAResult.fromJson(v));
        }
      });
    }

    return NHTSAVehicleInfo(
      count: json['Count'],
      message: json['Message'],
      searchCriteria: json['SearchCriteria'],
      results: results,
    );
  }

  static String _normalizeStringValue(String s) {
    return s.splitMapJoin(' ',
        onNonMatch: (m) => StringUtils.capitalize(m.toLowerCase()));
  }

  /// Lookup the value of a variable by its [variableId] in the NHTSA DB results
  String? valueFromId(int variableId) {
    final index =
        results.indexWhere((element) => element.variableId == variableId);
    return index == -1 ? null : _normalizeStringValue(results[index].value);
  }

  /// Lookup the value of a named [variable] in the NHTSA DB results
  String? value(String variable) {
    final index = results.indexWhere((element) => element.variable == variable);
    return index == -1 ? null : _normalizeStringValue(results[index].value);
  }

  @override
  String toString() {
    return 'NHTSAVehicleInfo[count=$count, message=$message, searchCriteria=$searchCriteria, results=$results]';
  }
}
