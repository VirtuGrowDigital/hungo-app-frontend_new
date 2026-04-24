class AllAddressesModel {
  bool? status;
  List<Data>? data;

  AllAddressesModel({this.status, this.data});

  AllAddressesModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Data {
  String? sId;
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
  String? createdAt;
  String? updatedAt;

  Data(
      {this.sId,
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
        this.createdAt,
        this.updatedAt});

  Data.fromJson(Map<String, dynamic> json) {
    sId = json['_id'];
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
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['_id'] = sId;
    data['label'] = label;
    data['receiverName'] = receiverName;
    data['receiverPhone'] = receiverPhone;
    data['houseNumber'] = houseNumber;
    data['area'] = area;
    data['landmark'] = landmark;
    data['pinCode'] = pinCode;
    data['city'] = city;
    data['state'] = state;
    data['fullAddress'] = fullAddress;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['isDefault'] = isDefault;
    data['isServiceable'] = isServiceable;
    data['distanceInKm'] = distanceInKm;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}
