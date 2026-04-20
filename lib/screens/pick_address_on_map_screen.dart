import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hungzo_app/utils/ColorConstants.dart';
import 'package:latlong2/latlong.dart' as latlng;

class PickAddressOnMapScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const PickAddressOnMapScreen({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  @override
  State<PickAddressOnMapScreen> createState() => _PickAddressOnMapScreenState();
}

class _PickAddressOnMapScreenState extends State<PickAddressOnMapScreen> {
  static const double _gwaliorCenterLat = 26.2183;
  static const double _gwaliorCenterLng = 78.1828;
  static const double _serviceRadiusKm = 35;
  static const double _defaultZoom = 15;

  final MapController _mapController = MapController();

  late latlng.LatLng _selectedLatLng;
  Placemark? _selectedPlacemark;
  String? _resolveError;
  bool _isResolving = false;
  bool _isMovingMap = false;
  bool _isFetchingCurrentLocation = false;
  bool _isServiceable = false;
  double _distanceInKm = 0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _selectedLatLng = latlng.LatLng(
      widget.initialLatitude,
      widget.initialLongitude,
    );
    _checkServiceabilityAndResolve();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debounceResolveAddress() {
    _debounceTimer?.cancel();
    setState(() {
      _isResolving = true;
      _resolveError = null;
    });
    _debounceTimer = Timer(const Duration(milliseconds: 500), _resolveAddress);
  }

  void _updateSelectedLocation(
    latlng.LatLng latLng, {
    bool clearPlacemark = true,
    bool movingMap = false,
  }) {
    final distance =
        _distanceFromServiceArea(latLng.latitude, latLng.longitude);

    setState(() {
      _selectedLatLng = latLng;
      _distanceInKm = distance;
      _isServiceable = distance <= _serviceRadiusKm;
      _isMovingMap = movingMap;
      if (clearPlacemark) {
        _selectedPlacemark = null;
        _resolveError = null;
      }
    });
  }

  Future<void> _checkServiceabilityAndResolve() async {
    _updateSelectedLocation(_selectedLatLng, clearPlacemark: false);
    _debounceResolveAddress();
  }

  Future<void> _resolveAddress() async {
    if (!mounted) return;

    try {
      final placemarks = await placemarkFromCoordinates(
        _selectedLatLng.latitude,
        _selectedLatLng.longitude,
      );

      if (!mounted) return;

      setState(() {
        _selectedPlacemark = placemarks.isNotEmpty ? placemarks.first : null;
        _resolveError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedPlacemark = null;
        _resolveError = "Couldn't read address for this location";
      });
    } finally {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }

  double _distanceFromServiceArea(double lat, double lng) {
    return Geolocator.distanceBetween(
          lat,
          lng,
          _gwaliorCenterLat,
          _gwaliorCenterLng,
        ) /
        1000;
  }

  Future<void> _moveToCurrentLocation() async {
    if (_isFetchingCurrentLocation) return;

    setState(() => _isFetchingCurrentLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar("Turn on location services");
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnackBar("Location permission required");
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLatLng = latlng.LatLng(
        position.latitude,
        position.longitude,
      );

      _updateSelectedLocation(currentLatLng);
      _mapController.move(currentLatLng, 16);
      _debounceResolveAddress();
    } catch (_) {
      _showSnackBar("Couldn't get current location");
    } finally {
      if (mounted) {
        setState(() => _isFetchingCurrentLocation = false);
      }
    }
  }

  String _addressPreview() {
    final place = _selectedPlacemark;
    if (place == null) {
      return _resolveError ?? "Move the map to place the pin";
    }

    final parts = [
      place.name,
      place.street,
      place.subLocality,
      place.locality,
      place.administrativeArea,
      place.postalCode,
    ].where((value) => (value ?? "").trim().isNotEmpty).toList();

    if (parts.isEmpty) {
      return "Location marked on map";
    }

    return parts.join(", ");
  }

  void _confirmSelection() {
    if (!_isServiceable) {
      _showSnackBar(
        "Sorry, we only deliver within ${_serviceRadiusKm.toStringAsFixed(0)} km of Gwalior center",
      );
      return;
    }

    Navigator.pop(
      context,
      <String, dynamic>{
        "latitude": _selectedLatLng.latitude,
        "longitude": _selectedLatLng.longitude,
        "placemark": _selectedPlacemark,
        "isServiceable": _isServiceable,
        "distanceInKm": _distanceInKm,
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Pick Location on Map",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLatLng,
              initialZoom: _defaultZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (position, hasGesture) {
                _updateSelectedLocation(position.center, movingMap: hasGesture);
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _updateSelectedLocation(
                    event.camera.center,
                    clearPlacemark: false,
                    movingMap: false,
                  );
                  _debounceResolveAddress();
                }
              },
              onTap: (_, point) {
                _updateSelectedLocation(point);
                _mapController.move(point, _mapController.camera.zoom);
                _debounceResolveAddress();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hungzo.app',
                maxZoom: 19,
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: const latlng.LatLng(
                      _gwaliorCenterLat,
                      _gwaliorCenterLng,
                    ),
                    radius: _serviceRadiusKm * 1000,
                    useRadiusInMeter: true,
                    color: const Color(0x1A2E7D32),
                    borderColor: const Color(0x662E7D32),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            ],
          ),
          IgnorePointer(
            child: Center(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 150),
                offset: _isMovingMap ? const Offset(0, -0.08) : Offset.zero,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 180),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 42,
                        color: _isServiceable
                            ? ColorConstants.success
                            : ColorConstants.danger,
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isServiceable
                                ? ColorConstants.success
                                : ColorConstants.danger,
                            width: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isServiceable
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isServiceable
                      ? const Color(0x4D2E7D32)
                      : const Color(0x4DD32F2F),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isServiceable
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    size: 18,
                    color: _isServiceable
                        ? ColorConstants.success
                        : ColorConstants.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isServiceable
                          ? "Deliverable location • ${_distanceInKm.toStringAsFixed(1)} km from center"
                          : "Outside delivery area • ${_distanceInKm.toStringAsFixed(1)} km from center",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isServiceable
                            ? ColorConstants.success
                            : ColorConstants.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 120,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: "recenter-map",
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 4,
              onPressed: _moveToCurrentLocation,
              child: _isFetchingCurrentLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, size: 22),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x1A000000),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _isServiceable
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: _isServiceable
                                  ? ColorConstants.success
                                  : ColorConstants.danger,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isResolving
                                      ? "Finding address..."
                                      : _isMovingMap
                                          ? "Release map to confirm spot"
                                          : _isServiceable
                                              ? "Deliver here"
                                              : "Outside delivery area",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (!_isServiceable)
                                  const Text(
                                    "Please move pin to green area",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Selected Location",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _addressPreview(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${_selectedLatLng.latitude.toStringAsFixed(6)}, ${_selectedLatLng.longitude.toStringAsFixed(6)}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.pan_tool_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Drag the map or tap anywhere to place the pin exactly where you want delivery",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isResolving ? null : _confirmSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isServiceable
                                ? ColorConstants.success
                                : Colors.grey.shade300,
                            foregroundColor: _isServiceable
                                ? Colors.white
                                : Colors.grey.shade500,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade500,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isResolving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  _isServiceable
                                      ? "Confirm This Location"
                                      : "Select a Serviceable Location",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
