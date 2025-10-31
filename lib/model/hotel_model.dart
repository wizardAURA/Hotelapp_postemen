// Note: 'dart:convert' is not needed here, so it's removed.
// The JSON decoding happens in the api_service.dart file.

// This is the main response object
class ApiResponse {
  final bool status;
  final String message;
  final List<HotelResult> hotelList;
  final List<String> excludedHotels; // For pagination

  ApiResponse({
    required this.status,
    required this.message,
    required this.hotelList,
    required this.excludedHotels,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    var hotelList = <HotelResult>[];
    // Path based on the docs: data -> arrayOfHotelList
    if (json['data'] != null && json['data']['arrayOfHotelList'] != null) {
      hotelList = List<HotelResult>.from(
        json['data']['arrayOfHotelList'].map((x) => HotelResult.fromJson(x)),
      );
    }

    var excludedHotels = <String>[];
    // Path based on the docs: data -> arrayOfExcludedHotels
    if (json['data'] != null && json['data']['arrayOfExcludedHotels'] != null) {
      excludedHotels = List<String>.from(
        json['data']['arrayOfExcludedHotels'].map((x) => x as String),
      );
    }

    return ApiResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? 'Unknown error',
      hotelList: hotelList,
      excludedHotels: excludedHotels,
    );
  }
}

// This is the Hotel object, based on the 'arrayOfHotelList'
class HotelResult {
  final String propertyCode;
  final String propertyName;
  final String imageUrl;
  final String city;
  final String country;
  final String displayPrice;
  final double? googleRating;
  final int? googleRatingCount;

  HotelResult({
    required this.propertyCode,
    required this.propertyName,
    required this.imageUrl,
    required this.city,
    required this.country,
    required this.displayPrice,
    this.googleRating,
    this.googleRatingCount,
  });

  factory HotelResult.fromJson(Map<String, dynamic> json) {
    // Helper function to safely get nested values
    T? safeGet<T>(Map<String, dynamic> map, List<String> keys) {
      dynamic val = map;
      for (var key in keys) {
        if (val is Map<String, dynamic> && val.containsKey(key)) {
          val = val[key];
        } else {
          return null;
        }
      }
      return val is T ? val : null;
    }

    return HotelResult(
      propertyCode: json['propertyCode'] ?? 'N/A',
      propertyName: json['propertyName'] ?? 'Unknown Hotel',
      // Get image: propertyImage -> fullUrl
      imageUrl: safeGet<String>(json, ['propertyImage', 'fullUrl']) ?? '',
      // Get city: propertyAddress -> city
      city:
          safeGet<String>(json, ['propertyAddress', 'city']) ?? 'Unknown City',
      // Get country: propertyAddress -> country
      country:
          safeGet<String>(json, ['propertyAddress', 'country']) ??
          'Unknown Country',
      // Get price: propertyMinPrice -> displayAmount
      displayPrice:
          safeGet<String>(json, ['propertyMinPrice', 'displayAmount']) ?? 'N/A',
      // Get rating: googleReview -> data -> overallRating
      googleRating: safeGet<num>(json, [
        'googleReview',
        'data',
        'overallRating',
      ])?.toDouble(),
      // Get rating count: googleReview -> data -> totalUserRating
      googleRatingCount: safeGet<int>(json, [
        'googleReview',
        'data',
        'totalUserRating',
      ]),
    );
  }
}
