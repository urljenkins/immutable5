import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../di/service_locator.dart';
import 'services/places_service.dart';
import 'models/place_model.dart';
import 'models/submission_model.dart';
import 'add_place_page.dart';
import '../../shared/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../generated/app_localizations.dart';
import '../prayer/prayer_times_service.dart';

class PlacesPage extends StatefulWidget {
  const PlacesPage({super.key});

  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  final MapController _mapController = MapController();
  final PlacesService _placesService = getIt<PlacesService>();

  LatLng _center = const LatLng(21.3891, 39.8579); // Default to Mecca
  List<PlaceModel> _places = [];
  List<PlaceModel> _filteredPlaces = [];
  List<SubmissionModel> _pendingPlaces = [];
  bool _loading = false;
  bool _locationPermissionGranted = false;

  String _selectedFilter = 'all'; // all, mosque, quiet_room, outdoor

  String? _nextPrayerName;
  String? _nextPrayerTime;

  // Route vars
  bool _isRouteMode = false;
  List<LatLng> _routePoints = [];
  LatLng? _routeDestination;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    if (!mounted) return;
    setState(() => _loading = true);

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (!mounted) return;
      setState(() => _locationPermissionGranted = true);
      try {
        final position = await Geolocator.getCurrentPosition();
        if (!mounted) return;
        setState(() {
          _center = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_center, 13.0);
        _updatePrayerTimes();
        await _fetchPlaces();
      } catch (e) {
        // Fallback to default
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updatePrayerTimes() async {
    try {
       // Using the factory from DI - we need to resolve it properly.
       // Since `getIt` is available, we can grab the factory.
       final factory = getIt<PrayerTimesServiceFactory>();
       final service = factory(_center.latitude, _center.longitude, 2, 0); // Default method/madhab
       final next = await service.getNextPrayer();
       if (mounted) {
         setState(() {
           _nextPrayerName = next.key;
           _nextPrayerTime = "${next.value.hour}:${next.value.minute.toString().padLeft(2, '0')}";
         });
       }
    } catch (e) {
      // Ignore prayer time errors for map view
    }
  }

  Future<void> _fetchPlaces() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final places = await _placesService.getNearbyPlaces(
          _center.latitude, _center.longitude);
      final pending = await _placesService.getPendingPlaces();

      if (mounted) {
        setState(() {
          _places = places;
          _pendingPlaces = pending;
          _loading = false;
          _filterPlaces();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load places. Please try again.',
                style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterPlaces() {
    if (_selectedFilter == 'all') {
      _filteredPlaces = List.from(_places);
    } else {
      _filteredPlaces = _places.where((p) {
        if (_selectedFilter == 'mosque') return p.type == 'mosque' || p.type == 'formal';
        if (_selectedFilter == 'quiet_room') return p.type == 'informal';
        if (_selectedFilter == 'outdoor') return p.type == 'outdoor';
        return true;
      }).toList();
    }
  }

  Future<void> _planRoute(LatLng destination) async {
    setState(() {
      _loading = true;
      _routeDestination = destination;
    });

    try {
      final route = await _placesService.getRoute(_center, destination);
      if (mounted) {
        setState(() {
          _routePoints = route;
          _loading = false;
          _isRouteMode = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _toggleRouteMode() {
    setState(() {
      _isRouteMode = !_isRouteMode;
      if (!_isRouteMode) {
        _routePoints = [];
        _routeDestination = null;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tap on map to set destination', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            backgroundColor: AppColors.accent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filterPlaces();
    });
  }

  void _showPlaceDetails(PlaceModel place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.mosque, color: AppColors.accent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      place.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (place.details?['opening_hours'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.access_time,
                        color: AppColors.textSecondary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      place.details!['opening_hours'],
                      style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchMaps(place.lat, place.lng),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.directions),
                  label: Text(
                    AppLocalizations.of(context)!.getDirections,
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final googleMapsUrl =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch maps.',
                style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => _onFilterChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.cardSurface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Color _getMarkerColor(PlaceModel place) {
    switch (place.type) {
      case 'mosque':
      case 'formal':
        return AppColors.accent; // Gold
      case 'informal':
        return Colors.blueAccent;
      case 'outdoor':
        return Colors.green;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13.0,
              onTap: (tapPos, point) {
                if (_isRouteMode) {
                  _planRoute(point);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.immutable.five',
                // Dark mode filter could be added here if supported by tile provider
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Destination marker
                  if (_routeDestination != null)
                    Marker(
                      point: _routeDestination!,
                      width: 40,
                      height: 40,
                      child: Icon(Icons.flag, color: Colors.red, size: 40),
                    ),
                  // User location marker
                  if (_locationPermissionGranted)
                    Marker(
                      point: _center,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Places markers
                  ..._filteredPlaces.map((place) => Marker(
                        point: LatLng(place.lat, place.lng),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showPlaceDetails(place),
                          child: Icon(
                            Icons.location_on,
                            color: _getMarkerColor(place),
                            size: 40,
                          ),
                        ),
                      )),

                  // Pending markers
                  ..._pendingPlaces.map((place) => Marker(
                        point: LatLng(place.lat, place.lng),
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.location_on,
                          color: Colors.orange, // Orange for pending
                          size: 40,
                        ),
                      )),
                ],
              ),
            ],
          ),

          // Add Place FAB
          Positioned(
            bottom: 100,
            left: 20,
            child: FloatingActionButton.extended(
              heroTag: 'add_place',
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              label: Text(
                'Add Spot',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.add_location_alt),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPlacePage(initialLocation: _center),
                  ),
                );
                if (result == true) {
                  _fetchPlaces();
                }
              },
            ),
          ),

          // Header & Filter Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.prayerPlaces,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      if (_loading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () {
                            final center = _mapController.camera.center;
                            setState(() {
                              _center = center;
                            });
                            _fetchPlaces();
                          },
                        ),
                    ],
                  ),
                ),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Mosques', 'mosque'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Quiet Rooms', 'quiet_room'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Outdoor', 'outdoor'),
                    ],
                  ),
                ),

                // Next Prayer Overlay
                if (_nextPrayerName != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          'Next: $_nextPrayerName at $_nextPrayerTime',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Fab to center & Route Toggle
          Positioned(
            bottom: 100,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'route_toggle',
                  backgroundColor: _isRouteMode ? Colors.blue : AppColors.cardSurface,
                  onPressed: _toggleRouteMode,
                  child: Icon(Icons.directions, color: _isRouteMode ? Colors.white : AppColors.accent),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'my_location',
                  backgroundColor: AppColors.cardSurface,
                  onPressed: _initLocation,
                  child: Icon(Icons.my_location, color: AppColors.accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
