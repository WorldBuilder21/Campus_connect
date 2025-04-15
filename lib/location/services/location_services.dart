import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// This class handles the background location service initialization
class LocationService {
  // Make it a singleton
  static final LocationService _instance = LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Configure notification properly
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_channel_id',
      'Location Service',
      description: 'This channel is used for location tracking',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Create the notification channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Configure the service properly
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStartService,
        autoStart: false, // Don't auto-start, let's control this explicitly
        isForegroundMode: true,
        notificationChannelId: 'location_channel_id',
        initialNotificationTitle: 'Location Service',
        initialNotificationContent: 'CampusConn is sharing your location',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStartService,
        onBackground: onIosBackground,
      ),
    );

    debugPrint('Location service initialized');
  }

  // Start location tracking
  Future<void> startLocationSharing() async {
    debugPrint('Starting location sharing');

    // Check if location permission is granted
    final permission = await _checkLocationPermission();
    if (!permission) {
      debugPrint('Location permission not granted');
      return;
    }

    // Start the service
    final service = FlutterBackgroundService();
    await service.startService();
    debugPrint('Background service started');
  }

  // Stop location tracking
  Future<void> stopLocationSharing() async {
    debugPrint('Stopping location sharing');
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  // Check if location permissions are granted
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied');
      return false;
    }

    debugPrint('Location permission granted: $permission');
    return true;
  }
}

// Important: Top-level function for background execution
@pragma('vm:entry-point')
void onStartService(ServiceInstance service) async {
  // Register Flutter plugins
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  debugPrint('Starting background location service');

  // CRITICAL: This needs to be called immediately for Android 12+
  if (service is AndroidServiceInstance) {
    debugPrint('Setting as foreground service immediately');
    service.setAsForegroundService();
  }

  // Initialize Supabase in the background service
  await initializeSupabaseInBackground();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      debugPrint('Setting as foreground service from event');
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      debugPrint('Setting as background service from event');
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    debugPrint('Stopping background service from event');
    service.stopSelf();
  });

  // Define a less frequent interval for location updates to save battery
  const updateInterval = Duration(minutes: 5);

  // Set up periodic location updates
  Timer.periodic(updateInterval, (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Update notification info
        service.setForegroundNotificationInfo(
          title: "CampusConn",
          content: "Location sharing is active",
        );

        // Update location
        await updateLocation(service);
      }
    } else {
      await updateLocation(service);
    }
  });

  // Also update location immediately on start
  await updateLocation(service);
}

// Initialize Supabase in the background service
@pragma('vm:entry-point')
Future<void> initializeSupabaseInBackground() async {
  try {
    // Get Supabase credentials
    const supabaseUrl = 'https://zmmmfxxrwcvosoksxtgp.supabase.co';
    const supabaseAnonKey =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptbW1meHhyd2N2b3Nva3N4dGdwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyNjA2OTYsImV4cCI6MjA1NzgzNjY5Nn0.7QxDxdrIuMukz3IWfE3SUG5eqAPrjEv9DhLpf6rW49M';

    // Check if Supabase is already initialized
    bool isInitialized = false;
    try {
      final instance = Supabase.instance;
      isInitialized = true;
      debugPrint('Supabase already initialized in background service');
    } catch (e) {
      isInitialized = false;
      debugPrint('Supabase not yet initialized in background service');
    }

    // Initialize Supabase if not already initialized
    if (!isInitialized) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );
      debugPrint('Supabase initialized in background service');
    }
  } catch (e) {
    debugPrint('Error initializing Supabase in background: $e');
  }
}

// Important: Top-level function for iOS background execution
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// Helper method to update location - must be top-level
@pragma('vm:entry-point')
Future<void> updateLocation(ServiceInstance service) async {
  try {
    debugPrint('Updating location in background service');

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      service.invoke('locationUpdate', {
        'status': 'error',
        'message': 'Location services are disabled.',
      });
      return;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      service.invoke('locationUpdate', {
        'status': 'error',
        'message': 'Location permissions are denied.',
      });
      return;
    }

    // Get current position with timeout to prevent hanging
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('Location request timed out');
      },
    );

    debugPrint('Got location: ${position.latitude}, ${position.longitude}');

    service.invoke('locationUpdate', {
      'status': 'success',
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Update location in Supabase
    await updateLocationInSupabase(position, service);
  } catch (e) {
    debugPrint('Error updating location in background: $e');
    service.invoke('locationUpdate', {
      'status': 'error',
      'message': 'Error updating location: $e',
    });
  }
}

// Update location in Supabase - must be top-level
// Update location in Supabase - must be top-level
@pragma('vm:entry-point')
Future<void> updateLocationInSupabase(
    Position position, ServiceInstance service) async {
  try {
    // Try to get the Supabase instance
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('User not authenticated, skipping location update');
        service.invoke('locationUpdate', {
          'status': 'error',
          'message': 'User not authenticated',
        });
        return;
      }

      // First check if a record already exists
      final existingRecord = await supabase
          .from('user_locations')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existingRecord != null) {
        // If record exists, use update instead of upsert
        await supabase.from('user_locations').update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'last_updated': DateTime.now().toIso8601String(),
        }).eq('user_id', userId);
      } else {
        // If no record exists, insert a new one
        await supabase.from('user_locations').insert({
          'user_id': userId,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'last_updated': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('Successfully updated location in Supabase');
      service.invoke('locationUpdate', {
        'status': 'success',
        'message': 'Location updated in database',
      });

      // Store last update time in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'last_location_update', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error with Supabase instance: $e');
      // Try to re-initialize Supabase
      await initializeSupabaseInBackground();
      throw Exception('Supabase instance error: $e');
    }
  } catch (e) {
    debugPrint('Error updating location in Supabase: $e');
    service.invoke('locationUpdate', {
      'status': 'error',
      'message': 'Database error: $e',
    });
  }
}
