import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:campus_conn/location/api/location_repository.dart';
import 'package:campus_conn/config/theme.dart';
import 'package:campus_conn/profile/screens/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class NearbyUsersMapScreen extends ConsumerStatefulWidget {
  static const routeName = '/nearby-users';

  const NearbyUsersMapScreen({super.key});

  @override
  ConsumerState<NearbyUsersMapScreen> createState() =>
      _NearbyUsersMapScreenState();
}

class _NearbyUsersMapScreenState extends ConsumerState<NearbyUsersMapScreen>
    with WidgetsBindingObserver {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  final double _defaultZoom = 15.0;

  CameraPosition? _initialPosition;
  bool _isLoading = true;
  bool _isLocating = false;
  String? _errorMessage;
  Timer? _locationUpdateTimer;
  double _searchRadius = 5.0; // Default radius in km

  // Cache for marker icons to avoid regenerating them
  final Map<String, BitmapDescriptor> _markerIconCache = {};

  // Flag to track if the component is mounted
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    WidgetsBinding.instance.addObserver(this);

    // Delay initialization slightly to ensure everything is properly set up
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_isMounted) {
        _initializeMap();
      }
    });

    // Set up less frequent location updates to reduce stress on the system
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      if (_isMounted && !_isLocating && !_isLoading) {
        _updateUserLocation();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Make sure we refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed && _isMounted) {
      // Delay slightly to ensure everything is properly resumed
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isMounted) {
          _loadNearbyUsers();
        }
      });
    }
  }

  @override
  void dispose() {
    // Mark as unmounted first to prevent async operations from updating state
    _isMounted = false;

    // Cancel timers
    _locationUpdateTimer?.cancel();

    // Clean up map controller
    if (_controller.isCompleted) {
      _controller.future.then((controller) {
        controller.dispose();
      }).catchError((e) {
        debugPrint('Error disposing map controller: $e');
      });
    }

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeMap() async {
    if (!_isMounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locationRepo = ref.read(locationRepositoryProvider);

      // Try to update current user's location first
      try {
        await locationRepo.updateUserLocation();
      } catch (e) {
        debugPrint('Error updating user location during initialization: $e');
        // Continue anyway, we'll try to get the cached location
      }

      // Get current user's location
      try {
        final currentUserLocation = await Supabase.instance.client
            .from('user_locations')
            .select()
            .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
            .maybeSingle();

        if (currentUserLocation != null) {
          // Set initial camera position to current user's location
          _initialPosition = CameraPosition(
            target: LatLng(
              currentUserLocation['latitude'] as double,
              currentUserLocation['longitude'] as double,
            ),
            zoom: _defaultZoom,
          );
        } else {
          // If no location found, use a default location (could be campus center)
          _initialPosition = const CameraPosition(
            target:
                LatLng(5.6037, -0.1870), // Default to Accra, Ghana (example)
            zoom: 12.0,
          );

          debugPrint('No location found for current user, using default');
        }
      } catch (e) {
        debugPrint('Error getting current user location: $e');
        // Use a default location if we can't get the user's location
        _initialPosition = const CameraPosition(
          target: LatLng(5.6037, -0.1870), // Default to Accra, Ghana (example)
          zoom: 12.0,
        );
      }

      // Load nearby users
      if (_isMounted) {
        await _loadNearbyUsers();
      }
    } catch (e) {
      if (_isMounted) {
        setState(() {
          _errorMessage = 'Failed to initialize map: ${e.toString()}';
        });
      }
      debugPrint('Failed to initialize map: ${e.toString()}');
    } finally {
      if (_isMounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUserLocation() async {
    if (!_isMounted || _isLocating) return;

    setState(() {
      _isLocating = true;
    });

    try {
      final locationRepo = ref.read(locationRepositoryProvider);
      await locationRepo.updateUserLocation();

      // Refresh nearby users after updating location
      if (_isMounted) {
        await _loadNearbyUsers();
      }
    } catch (e) {
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update location: ${e.toString()}')),
        );
      }
      debugPrint('Failed to update location: ${e.toString()}');
    } finally {
      if (_isMounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _loadNearbyUsers() async {
    if (!_isMounted) return;

    try {
      final locationRepo = ref.read(locationRepositoryProvider);

      // Try to use getNearbyUsers, but fall back to manual calculation if it fails
      List<Map<String, dynamic>> nearbyUsers = [];

      try {
        // First attempt: Try the RPC function
        nearbyUsers = await locationRepo.getNearbyUsers(radius: _searchRadius);
      } catch (e) {
        debugPrint('Failed to use getNearbyUsers RPC function: $e');

        try {
          // Second attempt: Try the manual calculation
          debugPrint('Falling back to manual distance calculation');
          nearbyUsers =
              await locationRepo.getNearbyUsersManually(radius: _searchRadius);
        } catch (fallbackError) {
          debugPrint(
              'Manual nearby users calculation also failed: $fallbackError');
          // At this point, we'll just use an empty list
        }
      }

      // Clear existing markers
      _markers.clear();

      // Add markers for each nearby user
      for (final user in nearbyUsers) {
        try {
          if (!_isMounted) return;

          // Skip if critical data is missing
          if (user['latitude'] == null ||
              user['longitude'] == null ||
              user['user_id'] == null) {
            debugPrint('Skipping user with missing data: $user');
            continue;
          }

          // Use a simpler marker approach to avoid crashes
          final BitmapDescriptor markerIcon = await _getMarkerIcon(
            user['username'] ?? 'User',
            user['image_url'],
            user['user_id'],
          );

          final marker = Marker(
            markerId: MarkerId(user['user_id']),
            position: LatLng(user['latitude'], user['longitude']),
            // Navigate to profile on tap
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    userId: user['user_id'],
                    showBackBtn: true,
                  ),
                ),
              );
            },
            icon: markerIcon,
            infoWindow: InfoWindow(
              title: user['username'] ?? 'User',
              snippet: user['bio'] != null && user['bio'].toString().isNotEmpty
                  ? user['bio'].toString().length > 30
                      ? '${user['bio'].toString().substring(0, 30)}...'
                      : user['bio'].toString()
                  : 'Tap to view profile',
            ),
          );

          _markers.add(marker);
        } catch (e) {
          debugPrint('Error creating marker for user ${user['user_id']}: $e');
          // Continue with the next user if there's an error
        }
      }

      if (_isMounted) {
        setState(() {});
      }
    } catch (e) {
      if (_isMounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load nearby users: ${e.toString()}')),
        );
      }
      debugPrint('Failed to load nearby users: $e');
    }
  }

  // Get marker icon - with better error handling and simplification
  Future<BitmapDescriptor> _getMarkerIcon(
      String username, String? imageUrl, String userId) async {
    // Use a fallback if anything goes wrong
    try {
      // Check cache first
      final cacheKey = '$userId-${imageUrl ?? "default"}';
      if (_markerIconCache.containsKey(cacheKey)) {
        return _markerIconCache[cacheKey]!;
      }

      // If no image URL, use default
      if (imageUrl == null || imageUrl.isEmpty) {
        final icon =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
        _markerIconCache[cacheKey] = icon;
        return icon;
      }

      // Try to create a custom marker, but use a simpler approach
      try {
        // Try to load from network with timeout
        final response = await http
            .get(Uri.parse(imageUrl))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode != 200) {
          throw Exception('Failed to load image');
        }

        // Use a simpler custom marker to avoid the complex canvas operations
        final icon =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
        _markerIconCache[cacheKey] = icon;
        return icon;
      } catch (e) {
        debugPrint('Error loading profile image: $e');
        final icon =
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
        _markerIconCache[cacheKey] = icon;
        return icon;
      }
    } catch (e) {
      debugPrint('Error creating marker icon: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading || _isLocating ? null : _loadNearbyUsers,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _isLoading ? null : _showFilterDialog,
            tooltip: 'Adjust Radius',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _initialPosition == null
                  ? const Center(child: Text('Unable to get your location'))
                  : Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: _initialPosition!,
                          markers: _markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          mapToolbarEnabled: false,
                          compassEnabled: true,
                          zoomControlsEnabled: true,
                          onMapCreated: (GoogleMapController controller) {
                            _controller.complete(controller);
                          },
                        ),
                        if (_isLocating)
                          const Positioned(
                            top: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Chip(
                                backgroundColor: Colors.white,
                                label: Text('Updating location...'),
                                avatar: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Search radius: ${_searchRadius.toStringAsFixed(1)} km',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'map_location_fab',
        onPressed: _isLoading || _isLocating ? null : _updateUserLocation,
        tooltip: 'Update My Location',
        backgroundColor:
            _isLoading || _isLocating ? Colors.grey : AppTheme.primaryColor,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _showFilterDialog() {
    if (!_isMounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Search Radius'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_searchRadius.toStringAsFixed(1)} km'),
              Slider(
                value: _searchRadius,
                min: 0.5,
                max: 20.0,
                divisions: 39,
                onChanged: (value) {
                  setState(() {
                    _searchRadius = value;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_isMounted) {
                this.setState(() {});
                _loadNearbyUsers();
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
