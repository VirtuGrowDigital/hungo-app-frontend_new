class UpdateAddressModel {
  bool? status; // Nullable status
  String? message; // Nullable message
  Data? data; // Nullable Data object containing the address details

  UpdateAddressModel({this.status, this.message, this.data});

  // Factory method to create an object from JSON
  UpdateAddressModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  // Method to convert the object back to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    return data;
  }
}

class Data {
  String? sId; // Nullable
  String? label; // Nullable
  String? houseNumber; // Nullable
  String? area; // Nullable
  String? landmark; // Nullable
  String? pinCode; // Nullable
  String? city; // Nullable
  String? state; // Nullable
  String? fullAddress; // Nullable
  double? latitude; // Nullable
  double? longitude; // Nullable
  bool? isDefault; // Nullable
  bool? isServiceable; // Nullable
  double? distanceInKm; // Nullable
  String? createdAt; // Nullable
  String? updatedAt; // Nullable

  Data({
    this.sId,
    this.label,
    this.houseNumber,
    this.area,
    this.landmark,
    this.pinCode,
    this.city,
    this.state,
    this.fullAddress,
    this.latitude,
    this.longitude,
    this.isDefault,
    this.isServiceable,
    this.distanceInKm,
    this.createdAt,
    this.updatedAt,
  });

  // Factory method to create a Data object from JSON
  Data.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
    label = json['label'];
    houseNumber = json['houseNumber'];
    area = json['area'];
    landmark = json['landmark'];
    pinCode = json['pinCode'];
    city = json['city'];
    state = json['state'];
    fullAddress = json['fullAddress'];
    latitude = (json['latitude'] as num?)?.toDouble();
    longitude = (json['longitude'] as num?)?.toDouble();
    isDefault = json['isDefault'];
    isServiceable = json['isServiceable'];
    distanceInKm = (json['distanceInKm'] as num?)?.toDouble();
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  // Method to convert the Data object back to JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['_id'] = this.sId;
    data['label'] = this.label;
    data['houseNumber'] = this.houseNumber;
    data['area'] = this.area;
    data['landmark'] = this.landmark;
    data['pinCode'] = this.pinCode;
    data['city'] = this.city;
    data['state'] = this.state;
    data['fullAddress'] = this.fullAddress;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['isDefault'] = this.isDefault;
    data['isServiceable'] = this.isServiceable;
    data['distanceInKm'] = this.distanceInKm;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
