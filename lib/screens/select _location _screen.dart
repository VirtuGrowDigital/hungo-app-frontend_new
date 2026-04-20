import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hungzo_app/data/models/AllAddressesModel/all_addresses_model.dart'
    as address_model;
import 'package:hungzo_app/screens/pick_address_on_map_screen.dart';
import 'package:hungzo_app/screens/payment_method_screen.dart';
import 'package:hungzo_app/services/Api/api_services.dart';
import 'package:hungzo_app/services/Api/dio_client.dart';

import '../utils/ColorConstants.dart';

class SelectLocationScreen extends StatefulWidget {
  final String fulfillmentType;

  const SelectLocationScreen({
    super.key,
    required this.fulfillmentType,
  });

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  static const double _gwaliorCenterLat = 26.2183;
  static const double _gwaliorCenterLng = 78.1828;
  static const double _serviceRadiusKm = 35;

  final ApiService _apiService = ApiService(dio: DioClient().getDio());

  bool _isLoading = true;
  bool _isRefreshingLocation = false;
  List<address_model.Data> _savedAddresses = [];
  _SelectableAddress? _currentAddress;
  _SelectableAddress? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _loadCheckoutAddresses();
  }

  Future<void> _loadCheckoutAddresses() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadSavedAddresses(),
        _loadCurrentLocation(selectByDefault: true),
      ]);

      if (_selectedAddress == null) {
        final defaultSaved = _savedAddresses.firstWhere(
          (item) => item.isDefault == true,
          orElse: () => _savedAddresses.isNotEmpty
              ? _savedAddresses.first
              : address_model.Data(),
        );

        if (defaultSaved.sId != null) {
          _selectedAddress = _SelectableAddress.fromSaved(defaultSaved);
        }
      }
    } catch (e) {
      _showSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSavedAddresses() async {
    final response = await _apiService.getAllAddress();
    _savedAddresses = response.data ?? [];
  }

  Future<void> _loadCurrentLocation({bool selectByDefault = false}) async {
    if (mounted) {
      setState(() => _isRefreshingLocation = true);
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw "Location service is turned off";
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw "Location permission is required to use current address";
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = placemarks.isNotEmpty ? placemarks.first : Placemark();

      final currentAddress = _SelectableAddress(
        addressId: null,
        label: "Current Location",
        title: _firstNonEmpty(
          place.name,
          place.street,
          "Current address",
        ),
        subtitle: _joinNonEmpty([
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ]),
        fullAddress: _joinNonEmpty([
          place.name,
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ]),
        latitude: position.latitude,
        longitude: position.longitude,
        isDefault: true,
        isServiceable: _isWithinServiceArea(
          position.latitude,
          position.longitude,
        ),
        distanceInKm: _distanceFromServiceArea(
          position.latitude,
          position.longitude,
        ),
        isCurrentLocation: true,
      );

      if (!mounted) return;

      setState(() {
        _currentAddress = currentAddress;
        if (selectByDefault || _selectedAddress == null) {
          _selectedAddress = currentAddress;
        }
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isRefreshingLocation = false);
      }
    }
  }

  Future<void> _openAddAddressSheet() async {
    final pickedLocation =
        await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => PickAddressOnMapScreen(
          initialLatitude: _currentAddress?.latitude ?? _gwaliorCenterLat,
          initialLongitude: _currentAddress?.longitude ?? _gwaliorCenterLng,
        ),
      ),
    );

    if (!mounted || pickedLocation == null) return;

    final isServiceable = pickedLocation["isServiceable"] as bool? ?? false;
    if (!isServiceable) {
      _showSnackBar(
        "Sorry, this location is outside our delivery area. Please select a location within Gwalior.",
      );
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAddressSheet(
        apiService: _apiService,
        initialLatitude: (pickedLocation["latitude"] as num?)?.toDouble(),
        initialLongitude: (pickedLocation["longitude"] as num?)?.toDouble(),
        initialPlacemark: pickedLocation["placemark"] as Placemark?,
        distanceInKm: (pickedLocation["distanceInKm"] as num?)?.toDouble(),
      ),
    );

    if (result == true) {
      await _loadCheckoutAddresses();
    }
  }

  void _continueWithSelectedAddress() {
    final selected = _selectedAddress;
    if (selected == null) {
      _showSnackBar("Select a delivery address first");
      return;
    }

    if (!selected.isServiceable) {
      _showSnackBar(
        "Delivery is available only in Gwalior right now. Choose a serviceable address.",
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodScreen(
          addressId: selected.addressId,
          address: selected.fullAddress,
          fulfillmentType: widget.fulfillmentType,
          lat: selected.latitude,
          lng: selected.longitude,
        ),
      ),
    );
  }

  bool _isWithinServiceArea(double lat, double lng) {
    return _distanceFromServiceArea(lat, lng) <= _serviceRadiusKm;
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

  String _joinNonEmpty(List<String?> parts) {
    return parts
        .map((part) => (part ?? "").trim())
        .where((part) => part.isNotEmpty)
        .join(", ");
  }

  String _firstNonEmpty(String? first, String? second, String fallback) {
    for (final value in [first, second]) {
      final trimmed = (value ?? "").trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedAddress;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Choose Delivery Address",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openAddAddressSheet,
                          icon: const Icon(Icons.add_location_alt_outlined,
                              size: 20),
                          label: const Text("Add New Address"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.success,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: IconButton(
                          onPressed: _isRefreshingLocation
                              ? null
                              : () =>
                                  _loadCurrentLocation(selectByDefault: true),
                          icon: _isRefreshingLocation
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.my_location, size: 22),
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: ColorConstants.success,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Current Address",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_currentAddress != null)
                    _addressCard(_currentAddress!, selected)
                  else
                    _emptyStateCard(
                      "Current location not available yet",
                      "Turn on GPS or tap the location button to refresh.",
                    ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Saved Addresses",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _savedAddresses.isEmpty
                        ? _emptyStateCard(
                            "No saved addresses",
                            "Add one address with geo location to speed up checkout.",
                          )
                        : ListView.separated(
                            itemCount: _savedAddresses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final address = _SelectableAddress.fromSaved(
                                _savedAddresses[index],
                              );
                              return _addressCard(address, selected);
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: selected != null && selected.isServiceable
                          ? _continueWithSelectedAddress
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selected != null && selected.isServiceable
                                ? ColorConstants.success
                                : Colors.grey.shade300,
                        foregroundColor:
                            selected != null && selected.isServiceable
                                ? Colors.white
                                : Colors.grey.shade500,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: selected != null && !selected.isServiceable
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.info_outline, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  "Select a Serviceable Address",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  selected == null
                                      ? "Select Address to Continue"
                                      : "Continue to Payment",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _emptyStateCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  title.contains("not available")
                      ? Icons.gps_off_outlined
                      : Icons.folder_outlined,
                  size: 22,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.4,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressCard(
      _SelectableAddress address, _SelectableAddress? selected) {
    final isSelected =
        selected?.selectionKey == address.selectionKey && selected != null;

    return InkWell(
      onTap: () {
        if (address.isServiceable) {
          setState(() => _selectedAddress = address);
        } else {
          _showSnackBar(
            "This address is outside our delivery area. Please choose a different location.",
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? ColorConstants.success
                : address.isServiceable
                    ? Colors.grey.shade200
                    : Colors.grey.shade100,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0x262E7D32),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with background
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: address.isServiceable
                    ? address.isCurrentLocation
                        ? const Color(0xFFE3F2FD)
                        : const Color(0xFFE8F5E9)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                address.isCurrentLocation
                    ? Icons.my_location
                    : Icons.location_on_outlined,
                color: address.isServiceable
                    ? address.isCurrentLocation
                        ? Colors.blue
                        : ColorConstants.success
                    : ColorConstants.danger,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label and Default badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          address.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: address.isServiceable
                                ? Colors.black87
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      if (address.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Default",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ColorConstants.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Title (house/building)
                  Text(
                    address.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: address.isServiceable
                          ? Colors.black87
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Subtitle (area/locality)
                  Text(
                    address.subtitle.isEmpty
                        ? address.fullAddress
                        : address.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: address.isServiceable
                          ? Colors.grey.shade600
                          : Colors.grey.shade300,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Serviceability badge and distance
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: address.isServiceable
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              address.isServiceable
                                  ? Icons.delivery_dining
                                  : Icons.block,
                              size: 12,
                              color: address.isServiceable
                                  ? ColorConstants.success
                                  : ColorConstants.danger,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              address.isServiceable
                                  ? "Deliverable"
                                  : "Not deliverable",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: address.isServiceable
                                    ? ColorConstants.success
                                    : ColorConstants.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${address.distanceInKm.toStringAsFixed(1)} km",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Selection indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? ColorConstants.success
                      : Colors.grey.shade300,
                  width: 2,
                ),
                color: isSelected ? ColorConstants.success : Colors.white,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableAddress {
  final String? addressId;
  final String label;
  final String title;
  final String subtitle;
  final String fullAddress;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final bool isServiceable;
  final double distanceInKm;
  final bool isCurrentLocation;

  const _SelectableAddress({
    required this.addressId,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.isServiceable,
    required this.distanceInKm,
    required this.isCurrentLocation,
  });

  String get selectionKey =>
      isCurrentLocation ? "current" : addressId ?? fullAddress;

  factory _SelectableAddress.fromSaved(address_model.Data address) {
    final fullAddress = ([
          address.fullAddress,
          [
            address.houseNumber,
            address.area,
            address.landmark,
            address.city,
            address.state,
            address.pinCode,
          ].where((value) => (value ?? "").trim().isNotEmpty).join(", "),
        ].firstWhere((value) => (value ?? "").trim().isNotEmpty,
            orElse: () => "")) ??
        "";

    return _SelectableAddress(
      addressId: address.sId,
      label: (address.label ?? "Saved Address").trim(),
      title: (address.houseNumber ?? address.area ?? "Saved address").trim(),
      subtitle: [
        address.area,
        address.landmark,
        address.city,
        address.state,
        address.pinCode,
      ].where((value) => (value ?? "").trim().isNotEmpty).join(", "),
      fullAddress: fullAddress,
      latitude: address.latitude ?? 0,
      longitude: address.longitude ?? 0,
      isDefault: address.isDefault ?? false,
      isServiceable: address.isServiceable ?? false,
      distanceInKm: address.distanceInKm ?? 0,
      isCurrentLocation: false,
    );
  }
}

class _AddAddressSheet extends StatefulWidget {
  final ApiService apiService;
  final double? initialLatitude;
  final double? initialLongitude;
  final Placemark? initialPlacemark;
  final double? distanceInKm;

  const _AddAddressSheet({
    required this.apiService,
    this.initialLatitude,
    this.initialLongitude,
    this.initialPlacemark,
    this.distanceInKm,
  });

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  static const double _gwaliorCenterLat = 26.2183;
  static const double _gwaliorCenterLng = 78.1828;
  static const double _serviceRadiusKm = 35;

  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController(text: "Office");
  final _houseController = TextEditingController();
  final _areaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController(text: "Gwalior");
  final _stateController = TextEditingController(text: "Madhya Pradesh");
  final _pinCodeController = TextEditingController();

  bool _isSaving = false;
  bool _isFetchingLocation = false;
  double? _latitude;
  double? _longitude;
  double? _distanceInKm;

  @override
  void initState() {
    super.initState();
    _distanceInKm = widget.distanceInKm;
    _applyPickedLocation(
      latitude: widget.initialLatitude,
      longitude: widget.initialLongitude,
      placemark: widget.initialPlacemark,
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    _houseController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _prefillFromCurrentLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw "Turn on location service to auto-fill this address";
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw "Location permission is required to save a geo-tagged address";
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final place = placemarks.isNotEmpty ? placemarks.first : Placemark();

      if (!mounted) return;

      _applyPickedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        placemark: place,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _pickAddressOnMap() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => PickAddressOnMapScreen(
          initialLatitude: _latitude ?? _gwaliorCenterLat,
          initialLongitude: _longitude ?? _gwaliorCenterLng,
        ),
      ),
    );

    if (result == null || !mounted) return;

    _applyPickedLocation(
      latitude: (result["latitude"] as num?)?.toDouble(),
      longitude: (result["longitude"] as num?)?.toDouble(),
      placemark: result["placemark"] as Placemark?,
    );
  }

  void _applyPickedLocation({
    required double? latitude,
    required double? longitude,
    Placemark? placemark,
  }) {
    if (latitude == null || longitude == null || !mounted) {
      return;
    }

    setState(() {
      final city = (placemark?.locality ?? "").trim();
      final state = (placemark?.administrativeArea ?? "").trim();

      _latitude = latitude;
      _longitude = longitude;
      _distanceInKm = Geolocator.distanceBetween(
            latitude,
            longitude,
            _gwaliorCenterLat,
            _gwaliorCenterLng,
          ) /
          1000;
      _houseController.text = [
        placemark?.name,
        placemark?.street,
      ].where((value) => (value ?? "").trim().isNotEmpty).join(", ");
      _areaController.text = [
        placemark?.subLocality,
        placemark?.locality,
      ].where((value) => (value ?? "").trim().isNotEmpty).join(", ");
      _cityController.text = city.isNotEmpty ? city : "Gwalior";
      _stateController.text = state.isNotEmpty ? state : "Madhya Pradesh";
      _pinCodeController.text = placemark?.postalCode ?? "";
    });
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Use current location or pick a point on the map first"),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final request = {
        "label": _labelController.text.trim(),
        "houseNumber": _houseController.text.trim(),
        "area": _areaController.text.trim(),
        "landmark": _landmarkController.text.trim(),
        "city": _cityController.text.trim(),
        "state": _stateController.text.trim(),
        "pinCode": _pinCodeController.text.trim(),
        "latitude": _latitude,
        "longitude": _longitude,
      };

      final response = await widget.apiService.addAddress(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message ?? "Address saved")),
      );
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data?["message"]?.toString() ??
                "Failed to save address",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _required(String? value, String fieldName) {
    if ((value ?? "").trim().isEmpty) {
      return "$fieldName is required";
    }
    return null;
  }

  String? _validatePinCode(String? value) {
    if ((value ?? "").trim().isEmpty) {
      return "Pin Code is required";
    }
    final trimmed = value!.trim();
    if (trimmed.length != 6) {
      return "Pin Code must be 6 digits";
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
      return "Pin Code must be numeric";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isServiceable =
        _distanceInKm != null && _distanceInKm! <= _serviceRadiusKm;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF8F9FA),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle bar
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
                    const SizedBox(height: 20),

                    // Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isServiceable
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isServiceable
                                ? Icons.check_circle
                                : Icons.info_outline,
                            color: isServiceable
                                ? ColorConstants.success
                                : ColorConstants.danger,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Add New Address",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _distanceInKm != null
                                    ? "${_distanceInKm!.toStringAsFixed(1)} km from delivery center"
                                    : "Location to be selected",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isServiceable
                                      ? ColorConstants.success
                                      : ColorConstants.danger,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Location buttons
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: _isFetchingLocation
                                  ? Colors.grey.shade200
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: _isFetchingLocation
                                    ? null
                                    : _prefillFromCurrentLocation,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isFetchingLocation)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      else
                                        Icon(
                                          Icons.my_location,
                                          size: 18,
                                          color: Colors.blue.shade600,
                                        ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Current Location",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _isFetchingLocation
                                              ? Colors.grey
                                              : Colors.blue.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: _pickAddressOnMap,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.map_outlined,
                                        size: 18,
                                        color: Colors.green.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        "Pick on Map",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green,
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
                    ),

                    const SizedBox(height: 20),

                    // Form fields
                    _field(_labelController, "Address Label",
                        hintText: "e.g., Home, Office, Other",
                        prefixIcon: Icons.label_outline),
                    _field(_houseController, "House / Building Name",
                        hintText: "Enter house or building name",
                        prefixIcon: Icons.home_outlined),
                    _field(_areaController, "Area / Locality",
                        hintText: "Enter your area or locality",
                        prefixIcon: Icons.location_city_outlined),
                    _field(_landmarkController, "Landmark (Optional)",
                        hintText: "Nearby landmark",
                        requiredField: false,
                        prefixIcon: Icons.place_outlined),
                    Row(
                      children: [
                        Expanded(
                          child: _field(_cityController, "City",
                              prefixIcon: Icons.business_outlined),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(_stateController, "State",
                              prefixIcon: Icons.public_outlined),
                        ),
                      ],
                    ),
                    _field(
                      _pinCodeController,
                      "Pin Code",
                      keyboardType: TextInputType.number,
                      hintText: "Enter 6-digit pin code",
                      prefixIcon: Icons.pin_outlined,
                      validator: _validatePinCode,
                    ),

                    // Location info
                    if (_latitude != null && _longitude != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isServiceable
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isServiceable
                                ? const Color(0x4D2E7D32)
                                : const Color(0x4DD32F2F),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isServiceable
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber_outlined,
                              size: 20,
                              color: isServiceable
                                  ? ColorConstants.success
                                  : ColorConstants.danger,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isServiceable
                                        ? "Location is serviceable"
                                        : "Outside delivery area",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isServiceable
                                          ? ColorConstants.success
                                          : ColorConstants.danger,
                                    ),
                                  ),
                                  Text(
                                    "${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                            _isSaving || !isServiceable ? null : _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isServiceable
                              ? ColorConstants.success
                              : Colors.grey.shade300,
                          foregroundColor: isServiceable
                              ? Colors.white
                              : Colors.grey.shade500,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_location, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Save Address",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    if (!isServiceable) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0x4DD32F2F),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: ColorConstants.danger,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Please select a location within Gwalior city limits to continue",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = true,
    String? Function(String?)? validator,
    String? hintText,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator ??
            (requiredField ? (value) => _required(value, label) : null),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 20, color: Colors.grey.shade600)
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: ColorConstants.success, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD32F2F)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
