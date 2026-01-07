import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../main.dart';
import '../api_service.dart';

class MapPickerPage extends StatefulWidget {
  final String title;
  final LatLng? initialPosition;

  const MapPickerPage({
    Key? key,
    required this.title,
    this.initialPosition,
  }) : super(key: key);

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late LatLng _selectedPosition;
  final MapController _mapController = MapController();
  String _selectedAddress = '';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    // Default to New York coordinates if no initial position
    _selectedPosition = widget.initialPosition ?? LatLng(40.7128, -74.0060);
  }

  void _onMapTap(TapPosition tapPosition, LatLng position) {
    setState(() {
      _selectedPosition = position;
      _isLoadingAddress = true;
    });

    // Get address from coordinates (reverse geocoding)
    _getAddressFromCoordinates(position);
  }

  Future<void> _getAddressFromCoordinates(LatLng position) async {
    try {
      // Use Nominatim reverse geocoding
      final predictions = await ApiService.getPlacePredictions(
        '${position.latitude},${position.longitude}',
      );

      if (predictions.isNotEmpty && mounted) {
        setState(() {
          _selectedAddress = predictions.first.description;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = 'Lat: ${position.latitude.toStringAsFixed(4)}, '
              'Lng: ${position.longitude.toStringAsFixed(4)}';
          _isLoadingAddress = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context, {
                'lat': _selectedPosition.latitude,
                'lng': _selectedPosition.longitude,
                'address': _selectedAddress,
              });
            },
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Select',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 13.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 80,
                    height: 80,
                    child: Icon(
                      Icons.location_pin,
                      size: 50,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Address info card at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Selected Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingAddress)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Getting address...'),
                        ],
                      )
                    else
                      Text(
                        _selectedAddress.isEmpty
                            ? 'Lat: ${_selectedPosition.latitude.toStringAsFixed(4)}, '
                                'Lng: ${_selectedPosition.longitude.toStringAsFixed(4)}'
                            : _selectedAddress,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap anywhere on the map to select a location',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
