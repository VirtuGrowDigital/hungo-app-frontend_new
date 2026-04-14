class CartItem {
  final String productId;
  final String? varietyId;
  final String name;
  final String image;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    this.varietyId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final variety = json['variety'];

    return CartItem(
      productId: json['productId']?.toString() ?? "",
      varietyId: variety != null ? variety['id']?.toString() : null,
      name: json['productName']?.toString() ?? "",
      image: json['image']?.toString() ?? "",

      price: variety != null
          ? double.tryParse(variety['price'].toString()) ?? 0.0
          : double.tryParse(json['price'].toString()) ?? 0.0,

      quantity: int.tryParse(json['quantity'].toString()) ?? 1,
    );
  }
}