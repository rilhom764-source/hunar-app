import 'dart:math';

class GeoUtils {
  static const double _earthRadiusKm = 6371.0;

  /// Haversine formula to calculate distance between two points in km
  static double haversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Filter items within a radius
  static List<T> filterByRadius<T>({
    required List<T> items,
    required double centerLat,
    required double centerLon,
    required double radiusKm,
    required double Function(T) getLatitude,
    required double Function(T) getLongitude,
  }) {
    return items.where((item) {
      final distance = haversineDistance(
        lat1: centerLat,
        lon1: centerLon,
        lat2: getLatitude(item),
        lon2: getLongitude(item),
      );
      return distance <= radiusKm;
    }).toList();
  }

  /// Sort items by distance
  static List<T> sortByDistance<T>({
    required List<T> items,
    required double centerLat,
    required double centerLon,
    required double Function(T) getLatitude,
    required double Function(T) getLongitude,
  }) {
    final list = List<T>.from(items);
    list.sort((a, b) {
      final distA = haversineDistance(
        lat1: centerLat,
        lon1: centerLon,
        lat2: getLatitude(a),
        lon2: getLongitude(a),
      );
      final distB = haversineDistance(
        lat1: centerLat,
        lon1: centerLon,
        lat2: getLatitude(b),
        lon2: getLongitude(b),
      );
      return distA.compareTo(distB);
    });
    return list;
  }

  /// Get distance between user and a point
  static double distanceTo({
    required double userLat,
    required double userLon,
    required double targetLat,
    required double targetLon,
  }) {
    return haversineDistance(
      lat1: userLat,
      lon1: userLon,
      lat2: targetLat,
      lon2: targetLon,
    );
  }
}

/// Known locations in Tajikistan
class TajikistanLocations {
  static const Map<String, Map<String, double>> cities = {
    'Dushanbe': {'lat': 38.5598, 'lon': 68.7740},
    'Khujand': {'lat': 40.2831, 'lon': 69.6289},
    'Kulob': {'lat': 38.5397, 'lon': 69.7850},
    'Bokhtar': {'lat': 37.8367, 'lon': 68.7811},
    'Istaravshan': {'lat': 39.9142, 'lon': 69.0036},
    'Vahdat': {'lat': 38.5564, 'lon': 69.0169},
    'Tursunzoda': {'lat': 38.5125, 'lon': 68.2314},
    'Konibodom': {'lat': 40.2925, 'lon': 70.4267},
    'Isfara': {'lat': 40.1267, 'lon': 70.6250},
    'Panjakent': {'lat': 39.4931, 'lon': 67.6078},
  };

  static Map<String, double> getCity(String name) {
    return cities[name] ?? cities['Dushanbe']!;
  }
}
