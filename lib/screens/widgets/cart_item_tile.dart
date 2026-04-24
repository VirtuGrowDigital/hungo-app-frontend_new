import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/cart_controller.dart';
import '../../utils/ColorConstants.dart';

class CartItemTile extends StatelessWidget {
  final CartItem item;
  final CartController controller;

  const CartItemTile({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final lineTotal = item.price * item.quantity;

    return Obx(
      () => Dismissible(
        key: ValueKey("${item.productId}_${item.varietyId}"),
        direction: controller.isUpdatingCart.value
            ? DismissDirection.none
            : DismissDirection.horizontal,
        onDismissed: (_) => controller.removeItem(item),
        background: _bg(Alignment.centerLeft),
        secondaryBackground: _bg(Alignment.centerRight),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffE9EDF4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  item.image,
                  width: 86,
                  height: 86,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 86,
                    height: 86,
                    color: const Color(0xffF2F4F7),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_outlined,
                      size: 30,
                      color: Color(0xff98A2B3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff111827),
                        height: 1.2,
                      ),
                    ),
                    if (item.varietyName.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.varietyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xff6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Swipe to remove',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.dashed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 74,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: controller.isUpdatingCart.value
                            ? const Color(0xffA8D5A2)
                            : const Color(0xff2F8F1E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.remove,
                                size: 16,
                                color: Colors.white,
                              ),
                              onPressed: controller.isUpdatingCart.value
                                  ? null
                                  : () => controller.decreaseQty(item),
                            ),
                          ),
                          Text(
                            item.quantity.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.white,
                              ),
                              onPressed: controller.isUpdatingCart.value
                                  ? null
                                  : () => controller.increaseQty(item),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.quantity > 1
                          ? '₹${item.price.toStringAsFixed(0)} each'
                          : '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xff9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${lineTotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff111827),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bg(Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: ColorConstants.error.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.delete_outline, color: ColorConstants.error),
    );
  }
}
