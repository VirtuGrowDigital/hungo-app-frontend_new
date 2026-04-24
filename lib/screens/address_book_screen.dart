import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hungzo_app/data/models/AllAddressesModel/all_addresses_model.dart'
    as address_model;
import 'package:hungzo_app/screens/pick_address_on_map_screen.dart';
import 'package:hungzo_app/services/Api/api_services.dart';
import 'package:hungzo_app/services/Api/dio_client.dart';
import 'package:hungzo_app/services/permissions/app_permission_service.dart';
import 'package:hungzo_app/utils/ColorConstants.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  final ApiService _apiService = ApiService(dio: DioClient().getDio());

  List<address_model.Data> _addresses = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _busyAddressId;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getAllAddress();
      setState(() {
        _addresses = response.data ?? [];
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openAddressForm({address_model.Data? address}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressFormSheet(
        apiService: _apiService,
        initialAddress: address,
      ),
    );

    if (result == true && mounted) {
      await _loadAddresses();
    }
  }

  Future<void> _deleteAddress(address_model.Data address) async {
    final addressId = address.sId;
    if (addressId == null || addressId.isEmpty) {
      _showSnackBar("This address can't be deleted right now.");
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete Address"),
            content: const Text(
              "Are you sure you want to remove this saved address?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    setState(() => _busyAddressId = addressId);

    try {
      final response = await _apiService.deleteAddress(addressId);
      _showSnackBar(response.message ?? "Address deleted successfully");
      await _loadAddresses();
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _busyAddressId = null);
      }
    }
  }

  Future<void> _makeDefault(address_model.Data address) async {
    final addressId = address.sId;
    if (addressId == null || addressId.isEmpty) {
      _showSnackBar("This address can't be updated right now.");
      return;
    }

    setState(() => _busyAddressId = addressId);

    try {
      final response = await _apiService.updateAddress(
        addressId,
        _addressRequest(address, isDefault: true),
      );
      _showSnackBar(response.message ?? "Default address updated");
      await _loadAddresses();
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _busyAddressId = null);
      }
    }
  }

  Map<String, dynamic> _addressRequest(
    address_model.Data address, {
    required bool isDefault,
  }) {
    return {
      "label": (address.label ?? "Address").trim(),
      "receiverName": (address.receiverName ?? "").trim(),
      "receiverPhone": (address.receiverPhone ?? "").trim(),
      "houseNumber": (address.houseNumber ?? address.fullAddress ?? "").trim(),
      "area": (address.area ?? "").trim(),
      "landmark": (address.landmark ?? "").trim(),
      "city": (address.city ?? "").trim(),
      "state": (address.state ?? "").trim(),
      "pinCode": (address.pinCode ?? "").trim(),
      "fullAddress": (address.fullAddress ?? "").trim(),
      "latitude": address.latitude,
      "longitude": address.longitude,
      "isDefault": isDefault,
    };
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text("Address Book"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddressForm(),
        backgroundColor: ColorConstants.success,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text("Add Address"),
      ),
      body: RefreshIndicator(
        color: ColorConstants.success,
        onRefresh: _loadAddresses,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.location_off_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: _loadAddresses,
              child: const Text("Try Again"),
            ),
          ),
        ],
      );
    }

    if (_addresses.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.location_city_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            "No saved addresses yet",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add your delivery addresses here so checkout is faster next time.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _addresses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final address = _addresses[index];
        final addressId = address.sId ?? '';
        final isBusy = _busyAddressId == addressId;
        final isDefault = address.isDefault ?? false;
        final isServiceable = address.isServiceable ?? false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDefault
                  ? ColorConstants.success.withValues(alpha: 0.35)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ColorConstants.success.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.place_outlined,
                      color: ColorConstants.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (address.label ?? "Address").trim(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (address.receiverName ?? "Saved address").trim(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isBusy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(
                    label: isDefault ? "Default" : "Saved",
                    color: isDefault ? ColorConstants.success : Colors.blueGrey,
                  ),
                  _chip(
                    label: isServiceable ? "Serviceable" : "Outside delivery area",
                    color: isServiceable ? Colors.green : Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                [
                  if ((address.receiverPhone ?? "").trim().isNotEmpty)
                    "Phone: ${address.receiverPhone!.trim()}",
                  if ((address.fullAddress ?? "").trim().isNotEmpty)
                    address.fullAddress!.trim(),
                  [
                    address.city,
                    address.state,
                    address.pinCode,
                  ].where((value) => (value ?? "").trim().isNotEmpty).join(", "),
                ].where((value) => value.trim().isNotEmpty).join("\n"),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : () => _openAddressForm(address: address),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text("Edit"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : () => _deleteAddress(address),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text("Delete"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              if (!isDefault) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isBusy ? null : () => _makeDefault(address),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.success,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.star_outline, size: 18),
                    label: const Text("Make Default"),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _chip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  static const double gwaliorCenterLat = 26.2183;
  static const double gwaliorCenterLng = 78.1828;
  static const double serviceRadiusKm = 35;

  final ApiService apiService;
  final address_model.Data? initialAddress;

  const _AddressFormSheet({
    required this.apiService,
    this.initialAddress,
  });

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _fullAddressController = TextEditingController();

  bool _isSaving = false;
  bool _isFetchingLocation = false;
  bool _isDefault = false;
  double? _latitude;
  double? _longitude;
  double? _distanceInKm;
  String _area = "";
  String _city = "";
  String _state = "";
  String _pinCode = "";

  bool get _isEditing => widget.initialAddress != null;

  @override
  void initState() {
    super.initState();
    final address = widget.initialAddress;
    if (address != null) {
      _labelController.text = (address.label ?? "Address").trim();
      _receiverNameController.text = (address.receiverName ?? "").trim();
      _receiverPhoneController.text = (address.receiverPhone ?? "").trim();
      _houseNumberController.text =
          (address.houseNumber ?? address.fullAddress ?? "").trim();
      _landmarkController.text = (address.landmark ?? "").trim();
      _fullAddressController.text = (address.fullAddress ?? "").trim();
      _isDefault = address.isDefault ?? false;
      _latitude = address.latitude;
      _longitude = address.longitude;
      _area = (address.area ?? "").trim();
      _city = (address.city ?? "").trim();
      _state = (address.state ?? "").trim();
      _pinCode = (address.pinCode ?? "").trim();

      if (_latitude != null && _longitude != null) {
        _distanceInKm = Geolocator.distanceBetween(
              _latitude!,
              _longitude!,
              _AddressFormSheet.gwaliorCenterLat,
              _AddressFormSheet.gwaliorCenterLng,
            ) /
            1000;
      } else {
        _distanceInKm = address.distanceInKm;
      }
    } else {
      _labelController.text = "Address";
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _houseNumberController.dispose();
    _landmarkController.dispose();
    _fullAddressController.dispose();
    super.dispose();
  }

  Future<void> _prefillFromCurrentLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      if (!mounted) return;

      final permission = await AppPermissionService.ensureLocationAccess(
        context,
        title: "Auto-fill from your location",
        message:
            "Allow location access to auto-fill this address with your current position.",
      );

      if (permission != PermissionRequestOutcome.granted) {
        return;
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

      _applyPickedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        placemark: placemarks.isNotEmpty ? placemarks.first : Placemark(),
      );
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
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
          initialLatitude: _latitude ?? _AddressFormSheet.gwaliorCenterLat,
          initialLongitude: _longitude ?? _AddressFormSheet.gwaliorCenterLng,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

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

    final area = [
      placemark?.subLocality,
      placemark?.locality,
    ].where((value) => (value ?? "").trim().isNotEmpty).join(", ");
    final city = (placemark?.locality ?? "").trim();
    final state = (placemark?.administrativeArea ?? "").trim();
    final postalCode = (placemark?.postalCode ?? "").trim();

    setState(() {
      _latitude = latitude;
      _longitude = longitude;
      _distanceInKm = Geolocator.distanceBetween(
            latitude,
            longitude,
            _AddressFormSheet.gwaliorCenterLat,
            _AddressFormSheet.gwaliorCenterLng,
          ) /
          1000;

      final resolvedFullAddress = [
        placemark?.name,
        placemark?.street,
        placemark?.subLocality,
        placemark?.locality,
        placemark?.administrativeArea,
        placemark?.postalCode,
      ].where((value) => (value ?? "").trim().isNotEmpty).join(", ");

      if (resolvedFullAddress.isNotEmpty) {
        _fullAddressController.text = resolvedFullAddress;
      }

      if (_houseNumberController.text.trim().isEmpty &&
          (placemark?.name ?? "").trim().isNotEmpty) {
        _houseNumberController.text = placemark!.name!.trim();
      }

      _area = area;
      _city = city;
      _state = state;
      _pinCode = postalCode;
    });
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showSnackBar("Use current location or pick a point on the map first.");
      return;
    }

    if (_city.isEmpty || _state.isEmpty || _pinCode.isEmpty) {
      _showSnackBar(
        "Please choose a map location with valid city, state, and pin code.",
      );
      return;
    }

    if ((_distanceInKm ?? (_AddressFormSheet.serviceRadiusKm + 1)) >
        _AddressFormSheet.serviceRadiusKm) {
      _showSnackBar(
        "This address is outside the delivery area. Please choose a serviceable location.",
      );
      return;
    }

    setState(() => _isSaving = true);

    final request = {
      "label": _labelController.text.trim(),
      "receiverName": _receiverNameController.text.trim(),
      "receiverPhone": _receiverPhoneController.text.trim(),
      "houseNumber": _houseNumberController.text.trim(),
      "area": _area,
      "landmark": _landmarkController.text.trim(),
      "city": _city,
      "state": _state,
      "pinCode": _pinCode,
      "fullAddress": _fullAddressController.text.trim(),
      "latitude": _latitude,
      "longitude": _longitude,
      "isDefault": _isDefault,
    };

    try {
      final message = _isEditing
          ? (await widget.apiService.updateAddress(
              widget.initialAddress!.sId!,
              request,
            ))
                  .message ??
              "Address updated successfully"
          : (await widget.apiService.addAddress(request)).message ??
              "Address added successfully";

      if (!mounted) {
        return;
      }

      _showSnackBar(message);
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String? _required(String? value, String fieldName) {
    if ((value ?? "").trim().isEmpty) {
      return "$fieldName is required";
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final trimmed = (value ?? "").trim();
    if (trimmed.isEmpty) {
      return "Phone number is required";
    }
    if (!RegExp(r'^[0-9]{10}$').hasMatch(trimmed)) {
      return "Phone number must be 10 digits";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isServiceable = (_distanceInKm ?? (_AddressFormSheet.serviceRadiusKm + 1)) <=
        _AddressFormSheet.serviceRadiusKm;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _isEditing ? "Edit Address" : "Add Address",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Manage saved addresses for faster checkout.",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _locationAction(
                          label: "Current Location",
                          icon: Icons.my_location,
                          color: Colors.blue.shade600,
                          loading: _isFetchingLocation,
                          onTap: _isFetchingLocation ? null : _prefillFromCurrentLocation,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _locationAction(
                          label: "Pick on Map",
                          icon: Icons.map_outlined,
                          color: Colors.green.shade600,
                          onTap: _pickAddressOnMap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _field(
                    controller: _labelController,
                    label: "Label",
                    hintText: "Home, Office, Shop",
                    validator: (value) => _required(value, "Label"),
                  ),
                  _field(
                    controller: _receiverNameController,
                    label: "Receiver Name",
                    hintText: "Enter receiver name",
                    validator: (value) => _required(value, "Receiver name"),
                  ),
                  _field(
                    controller: _receiverPhoneController,
                    label: "Phone Number",
                    hintText: "Enter 10-digit phone number",
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),
                  _field(
                    controller: _houseNumberController,
                    label: "House / Flat / Building",
                    hintText: "House number or building name",
                    validator: (value) => _required(value, "House or building"),
                  ),
                  _field(
                    controller: _landmarkController,
                    label: "Landmark",
                    hintText: "Optional landmark",
                  ),
                  _field(
                    controller: _fullAddressController,
                    label: "Complete Address",
                    hintText: "Street, area, locality",
                    maxLines: 3,
                    validator: (value) => _required(value, "Complete address"),
                  ),
                  SwitchListTile(
                    value: _isDefault,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: ColorConstants.success,
                    title: const Text(
                      "Set as default address",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      "This address will be preferred during checkout.",
                    ),
                    onChanged: (value) => setState(() => _isDefault = value),
                  ),
                  if (_latitude != null && _longitude != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: (isServiceable ? Colors.green : Colors.red)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: (isServiceable ? Colors.green : Colors.red)
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isServiceable
                                ? "Location is serviceable"
                                : "Outside delivery area",
                            style: TextStyle(
                              color: isServiceable ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [
                              if (_city.isNotEmpty) _city,
                              if (_state.isNotEmpty) _state,
                              if (_pinCode.isNotEmpty) _pinCode,
                              "${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}",
                            ].join(" • "),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstants.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(_isEditing ? "Update Address" : "Save Address"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: const Color(0xFFF7F9FC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
