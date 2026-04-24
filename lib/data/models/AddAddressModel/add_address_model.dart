class AddAddressModel {
  bool? status;
  String? message;
  Data? data;

  AddAddressModel({this.status, this.message, this.data});

  AddAddressModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data?.toJson();
    }
    return data;
  }
}

class Data {
  String? label;
  String? receiverName;
  String? receiverPhone;
  String? houseNumber;
  String? area;
  String? landmark;
  String? pinCode;
  String? city;
  String? state;
  String? fullAddress;
  double? latitude;
  double? longitude;
  bool? isDefault;
  bool? isServiceable;
  double? distanceInKm;
  String? sId;
  String? createdAt;
  String? updatedAt;

  Data({
    this.label,
    this.receiverName,
    this.receiverPhone,
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
    this.sId,
    this.createdAt,
    this.updatedAt,
  });

  Data.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    receiverName = json['receiverName'];
    receiverPhone = json['receiverPhone'];
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
    sId = json['_id'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['label'] = this.label;
    data['receiverName'] = this.receiverName;
    data['receiverPhone'] = this.receiverPhone;
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
    data['_id'] = this.sId;
    data['createdAt'] = this.createdAt;
    data['updatedAt'] = this.updatedAt;
    return data;
  }
}
