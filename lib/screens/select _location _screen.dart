import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hungzo_app/data/models/AllAddressesModel/all_addresses_model.dart'
    as address_model;
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
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAddressSheet(apiService: _apiService),
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
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: const Text("Add New Address"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _isRefreshingLocation
                            ? null
                            : () => _loadCurrentLocation(selectByDefault: true),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        icon: _isRefreshingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Current Address",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
                  const Text(
                    "Saved Addresses",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _continueWithSelectedAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        selected != null && !selected.isServiceable
                            ? "Choose a Serviceable Address"
                            : "Continue to Payment",
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
    );
  }

  Widget _emptyStateCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressCard(_SelectableAddress address, _SelectableAddress? selected) {
    final isSelected =
        selected?.selectionKey == address.selectionKey && selected != null;

    return InkWell(
      onTap: () {
        setState(() => _selectedAddress = address);
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
                : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: address.isCurrentLocation
                    ? const Color(0xFFFFEEF1)
                    : const Color(0xFFEAF7EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                address.isCurrentLocation
                    ? Icons.my_location
                    : Icons.location_on_outlined,
                color: address.isCurrentLocation
                    ? ColorConstants.danger
                    : ColorConstants.success,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          address.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (address.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7EE),
                            borderRadius: BorderRadius.circular(999),
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
                  const SizedBox(height: 6),
                  Text(
                    address.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.subtitle.isEmpty
                        ? address.fullAddress
                        : address.subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: address.isServiceable
                              ? const Color(0xFFEAF7EE)
                              : const Color(0xFFFFEEF1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          address.isServiceable
                              ? "Serviceable in Gwalior"
                              : "Outside service area",
                          style: TextStyle(
                            color: address.isServiceable
                                ? ColorConstants.success
                                : ColorConstants.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${address.distanceInKm.toStringAsFixed(1)} km",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected
                  ? ColorConstants.success
                  : Colors.grey.shade400,
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
      ]
          .where((value) => (value ?? "").trim().isNotEmpty)
          .join(", "),
    ].firstWhere((value) => (value ?? "").trim().isNotEmpty, orElse: () => "")) ??
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

  const _AddAddressSheet({
    required this.apiService,
  });

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
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

  @override
  void initState() {
    super.initState();
    _prefillFromCurrentLocation();
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

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _houseController.text = [
          place.name,
          place.street,
        ].where((value) => (value ?? "").trim().isNotEmpty).join(", ");
        _areaController.text = [
          place.subLocality,
          place.locality,
        ].where((value) => (value ?? "").trim().isNotEmpty).join(", ");
        _cityController.text =
            (place.locality ?? "").trim().isNotEmpty ? place.locality! : "Gwalior";
        _stateController.text = (place.administrativeArea ?? "").trim().isNotEmpty
            ? place.administrativeArea!
            : "Madhya Pradesh";
        _pinCodeController.text = place.postalCode ?? "";
      });
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

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Detect current location first to geo-tag this address"),
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
            e.response?.data?["message"]?.toString() ?? "Failed to save address",
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F9FC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Center(
                      child: Icon(Icons.drag_handle, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Add New Address",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "We save latitude and longitude with every address so delivery can be validated in Gwalior.",
                      style: TextStyle(
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed:
                          _isFetchingLocation ? null : _prefillFromCurrentLocation,
                      icon: _isFetchingLocation
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: const Text("Use Current Location"),
                    ),
                    const SizedBox(height: 14),
                    _field(_labelController, "Label", validator: (value) {
                      return _required(value, "Label");
                    }),
                    _field(_houseController, "House / Building"),
                    _field(_areaController, "Area / Locality"),
                    _field(_landmarkController, "Landmark", requiredField: false),
                    _field(_cityController, "City"),
                    _field(_stateController, "State"),
                    _field(
                      _pinCodeController,
                      "Pin Code",
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _latitude != null && _longitude != null
                          ? "Geo-tagged at ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}"
                          : "Location not tagged yet",
                      style: TextStyle(
                        color: _latitude != null
                            ? ColorConstants.success
                            : ColorConstants.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                "Save Address",
                                style: TextStyle(
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
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator ??
            (requiredField
                ? (value) => _required(value, label)
                : null),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: ColorConstants.success),
          ),
        ),
      ),
    );
  }
}
