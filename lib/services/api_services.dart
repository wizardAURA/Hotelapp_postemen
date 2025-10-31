import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:hotelapp/model/hotel_model.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ApiService {
  final String _baseUrl = "https://api.mytravaly.com/public/v1/";
  final String _authToken = "71523fdd8d26f585315b4233e39d9263";
  final int _limit = 5; // <-- FIX: Changed from 10 to 5

  // Helper function to get device details
  Future<Map<String, dynamic>> _getDeviceDetails() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    Map<String, dynamic> deviceData = {};

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceData = {
          "deviceModel": androidInfo.model,
          "deviceFingerprint": androidInfo.fingerprint,
          "deviceBrand": androidInfo.brand,
          "deviceId": androidInfo.id,
          "deviceName": androidInfo.device,
          "deviceManufacturer": androidInfo.manufacturer,
          "deviceProduct": androidInfo.product,
          "deviceSerialNumber": "unknown",
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceData = {
          "deviceModel": iosInfo.model,
          "deviceFingerprint": iosInfo.identifierForVendor,
          "deviceBrand": "Apple",
          "deviceId": iosInfo.identifierForVendor,
          "deviceName": iosInfo.name,
          "deviceManufacturer": "Apple",
          "deviceProduct": iosInfo.utsname.machine,
          "deviceSerialNumber": "unknown",
        };
      }
    } catch (e) {
      print("Failed to get device info: $e");

      deviceData = {
        "deviceModel": "Generic",
        "deviceFingerprint": "unknown",
        "deviceBrand": "unknown",
        "deviceId": "unknown",
        "deviceName": "unknown",
        "deviceManufacturer": "unknown",
        "deviceProduct": "unknown",
        "deviceSerialNumber": "unknown",
      };
    }
    return deviceData;
  }

  Future<String> registerDevice() async {
    final Uri uri = Uri.parse(_baseUrl);

    final Map<String, dynamic> deviceDetails = await _getDeviceDetails();

    final body = {"action": "deviceRegister", "deviceRegister": deviceDetails};

    try {
      final response = await http.post(
        uri,
        headers: {
          'authtoken': _authToken,
          'Content-Type': 'application/json',
          'User-Agent': 'Dart/2.12 (dart:io)',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['data']['visitorToken'];
        if (token != null) {
          print("SUCCESS: Got visitorToken: $token");
          return token;
        } else {
          throw Exception('Visitor token was null in response');
        }
      } else {
        throw Exception(
          'Failed to register device (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      print("Error in registerDevice: $e");
      throw Exception('Failed to register device: $e');
    }
  }

  Future<ApiResponse> searchHotels({
    required String query,
    required String visitorToken,
    required List<String> previouslyLoadedHotels,
  }) async {
    final Uri uri = Uri.parse(_baseUrl);
    final body = {
      "action": "getSearchResultListOfHotels",
      "getSearchResultListOfHotels": {
        "searchCriteria": {
          "checkIn": "2026-07-11",
          "checkOut": "2026-07-12",
          "rooms": 1,
          "adults": 2,
          "children": 0,
          "searchType": "countrySearch",
          "searchQuery": [query],
          "accommodation": ["all"],
          "arrayOfExcludedSearchType": ["street"],
          "highPrice": "3000000",
          "lowPrice": "0",
          "limit": _limit,
          "preloaderList": previouslyLoadedHotels,
          "currency": "INR",
          "rid": 0,
        },
      },
    };

    try {
      final response = await http.post(
        uri,
        headers: {
          'authtoken': _authToken,
          'visitortoken': visitorToken,
          'Content-Type': 'application/json',
          'User-Agent': 'Dart/2.12 (dart:io)',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return ApiResponse.fromJson(json.decode(response.body));
      } else {
        String errorMessage;
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? 'Failed to load hotels';
        } catch (e) {
          errorMessage = response.body.isNotEmpty
              ? response.body
              : 'Unknown error';
        }
        throw Exception(
          'Failed to load hotels (${response.statusCode}): $errorMessage',
        );
      }
    } catch (e) {
      print("Error in ApiService: $e");
      if (e is FormatException) {
        throw Exception('Failed to parse server response. Please try again.');
      }
      throw Exception(e.toString());
    }
  }
}
