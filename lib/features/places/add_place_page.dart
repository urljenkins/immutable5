import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../di/service_locator.dart';
import '../../shared/app_colors.dart';
import 'models/submission_model.dart';
import 'services/places_service.dart';

class AddPlacePage extends StatefulWidget {
  final LatLng initialLocation;

  const AddPlacePage({super.key, required this.initialLocation});

  @override
  State<AddPlacePage> createState() => _AddPlacePageState();
}

class _AddPlacePageState extends State<AddPlacePage> {
  int _currentStep = 0;
  String? _selectedCategory;
  late LatLng _selectedLocation;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _wuduAvailable = false;
  bool _womenSpaceAvailable = false;
  bool _submitting = false;

  final MapController _mapController = MapController();

  final List<Map<String, dynamic>> _categories = [
    {'id': 'mosque', 'label': 'Mosque', 'icon': Icons.mosque},
    {'id': 'prayer_room', 'label': 'Prayer Room', 'icon': Icons.meeting_room},
    {'id': 'quiet_room', 'label': 'Quiet Room', 'icon': Icons.chair},
    {'id': 'outdoor', 'label': 'Outdoor', 'icon': Icons.park},
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Prayer Spot',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: AppColors.cardSurface,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
          Expanded(
            child: _buildStepContent(),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildCategoryStep();
      case 1:
        return _buildLocationStep();
      case 2:
        return _buildDetailsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCategoryStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What kind of place is this?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['id'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category['id']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.2)
                          : AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category['icon'],
                          size: 40,
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          category['label'],
                          style: GoogleFonts.plusJakartaSans(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _selectedLocation,
            initialZoom: 15.0,
            onPositionChanged: (pos, hasGesture) {
              _selectedLocation = pos.center;
                        },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.immutable.five',
            ),
          ],
        ),
        Center(
          child: Icon(
            Icons.location_on,
            size: 50,
            color: AppColors.accent,
          ),
        ),
        Positioned(
          top: 24,
          left: 24,
          right: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Move the map to place the pin exactly at the entrance.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us more',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Name of Place',
              hintText: 'e.g., Terminal 3 Prayer Room',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.cardSurface,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            style: const TextStyle(color: AppColors.textPrimary),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description / Instructions',
              hintText: 'e.g., Located near Gate 45, ask security for key...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.cardSurface,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Facilities',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _wuduAvailable,
            onChanged: (val) => setState(() => _wuduAvailable = val),
            title: Text('Wudu Area Available', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary)),
            activeThumbColor: AppColors.accent,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _womenSpaceAvailable,
            onChanged: (val) => setState(() => _womenSpaceAvailable = val),
            title: Text('Women\'s Space Available', style: GoogleFonts.plusJakartaSans(color: AppColors.textPrimary)),
            activeThumbColor: AppColors.accent,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _submitting ? null : () => setState(() => _currentStep--),
              child: Text(
                'Back',
                style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
              ),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: _submitting ? null : _handleNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _currentStep == 2 ? 'Submit' : 'Next',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    setState(() => _submitting = true);

    final submission = SubmissionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      category: _selectedCategory!,
      lat: _selectedLocation.latitude,
      lng: _selectedLocation.longitude,
      wuduAvailable: _wuduAvailable,
      womenSpaceAvailable: _womenSpaceAvailable,
      description: _descriptionController.text,
      submittedBy: 'User', // Mocked user
      submissionDate: DateTime.now(),
    );

    await getIt<PlacesService>().submitPlace(submission);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spot submitted for verification!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true); // Return true to indicate success
    }
  }
}
