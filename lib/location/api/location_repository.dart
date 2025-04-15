import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class LocationRepository {
  final SupabaseClient _supabase;

  LocationRepository(this._supabase);

  // Update the current user's location
// Update the current user's location
  Future<void> updateUserLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check if we have permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Location request timed out.'),
      );

      // Get current user ID
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated.');
      }

      // First check if a record already exists
      final existingRecord = await _supabase
          .from('user_locations')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existingRecord != null) {
        // If record exists, use update instead of upsert
        await _supabase.from('user_locations').update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'last_updated': DateTime.now().toIso8601String(),
        }).eq('user_id', userId);
      } else {
        // If no record exists, insert a new one
        await _supabase.from('user_locations').insert({
          'user_id': userId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'last_updated': DateTime.now().toIso8601String(),
        });
      }

      debugPrint(
          'Location updated: ${position.latitude}, ${position.longitude}');
      return;
    } catch (e) {
      debugPrint('Error updating location: $e');
      rethrow;
    }
  }

  // Get nearby users within a certain radius (in kilometers)
  Future<List<Map<String, dynamic>>> getNearbyUsers(
      {double radius = 5.0}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get current user's location
      final currentUserLocation = await _supabase
          .from('user_locations')
          .select()
          .eq('user_id', userId)
          .single();

      final latitude = currentUserLocation['latitude'] as double;
      final longitude = currentUserLocation['longitude'] as double;

      // Using the nearby_users function
      final response = await _supabase.rpc('nearby_users', params: {
        'lat': latitude,
        'lng': longitude,
        'radius_km': radius,
        'current_user_id': userId,
      });

      // Additional logging to debug SQL errors
      debugPrint('Nearby users response: $response');

      // If we get an empty response, return an empty list
      if (response == null) return [];

      // Parse response to include both location and user data
      return (response as List<dynamic>)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error getting nearby users: $e');
      rethrow;
    }
  }

  // Fallback method if RPC function doesn't work
  Future<List<Map<String, dynamic>>> getNearbyUsersManually(
      {double radius = 5.0}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get current user's location
      final currentUserLocationResponse = await _supabase
          .from('user_locations')
          .select()
          .eq('user_id', userId)
          .single();

      final currentLat = currentUserLocationResponse['latitude'] as double;
      final currentLng = currentUserLocationResponse['longitude'] as double;

      // Get all other users' locations
      final locationsResponse = await _supabase
          .from('user_locations')
          .select('*, accounts!inner(*)')
          .neq('user_id', userId);

      final result = <Map<String, dynamic>>[];

      // Calculate distances manually using the Haversine formula
      for (final location in locationsResponse) {
        final lat = location['latitude'] as double;
        final lng = location['longitude'] as double;

        // Calculate distance using the Haversine formula
        final distance =
            _calculateHaversineDistance(currentLat, currentLng, lat, lng);

        // Only include users within the radius
        if (distance <= radius) {
          final account = location['accounts'] as Map<String, dynamic>;

          result.add({
            'user_id': account['id'],
            'username': account['username'],
            'bio': account['bio'],
            'image_url': account['image_url'],
            'latitude': lat,
            'longitude': lng,
            'distance_km': distance,
          });
        }
      }

      // Sort by distance
      result.sort((a, b) =>
          (a['distance_km'] as double).compareTo(b['distance_km'] as double));

      return result;
    } catch (e) {
      debugPrint('Error getting nearby users manually: $e');
      rethrow;
    }
  }

  // Calculate distance between two points using Haversine formula
  double _calculateHaversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in kilometers

    // Convert degrees to radians
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    // Haversine formula
    final a = (1 - _cos(dLat)) / 2 +
        _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) * (1 - _cos(dLon)) / 2;

    final c = 2 * _asin(_sqrt(a));
    return R * c;
  }

  // Helper math functions
  double _toRadians(double degree) {
    return degree * (3.14159265359 / 180);
  }

  double _sin(double x) {
    return 0 - _cos(x - 3.14159265359 / 2);
  }

  double _cos(double x) {
    // Taylor series approximation of cosine
    double result = 1;
    double term = 1;
    double x2 = x * x;

    for (int i = 1; i <= 6; i++) {
      term = term * x2 / ((2 * i - 1) * (2 * i));
      result += (i % 2 == 1) ? -term : term;
    }

    return result;
  }

  double _asin(double x) {
    // Simple approximation of arcsin
    return x + (x * x * x) / 6 + (3 * x * x * x * x * x) / 40;
  }

  double _sqrt(double x) {
    // Newton's method for square root
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(Supabase.instance.client);
});
