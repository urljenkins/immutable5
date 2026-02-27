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
  List<SubmissionModel> _pendingPlaces = [];
  bool _loading = false;
  bool _locationPermissionGranted = false;

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
        await _fetchPlaces();
      } catch (e) {
        // Fallback to default
      }
    }

    if (mounted) setState(() => _loading = false);
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
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.immutable.five',
                // Dark mode filter could be added here if supported by tile provider
              ),
              MarkerLayer(
                markers: [
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
                  ..._places.map((place) => Marker(
                        point: LatLng(place.lat, place.lng),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showPlaceDetails(place),
                          child: Icon(
                            Icons.location_on,
                            color: AppColors.accent,
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

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
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
                        // Re-fetch based on current map center
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
          ),

          // Fab to center
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: AppColors.cardSurface,
              child: Icon(Icons.my_location, color: AppColors.accent),
              onPressed: _initLocation,
            ),
          ),
        ],
      ),
    );
  }
}
