import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';

class SearchDishBar extends GetView<HomeController> {
  const SearchDishBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.searchFocusNode,
      builder: (context, _) {
        return Obx(
          () => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: controller.searchFocusNode.hasFocus
                    ? const Color(0xFF17392D)
                    : const Color(0xFFE0EAE5),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF113B2C).withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchTextController,
              focusNode: controller.searchFocusNode,
              textInputAction: TextInputAction.search,
              onChanged: controller.onSearchChanged,
              onSubmitted: controller.searchProducts,
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.search_rounded,
                    color: Color(0xFF17392D),
                    size: 22,
                  ),
                ),
                hintText: "Search products or categories",
                hintStyle: const TextStyle(
                  color: Color(0xFF91A39A),
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                suffixIcon: controller.isSearchLoading.value
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : controller.searchQuery.value.isNotEmpty
                        ? IconButton(
                            onPressed: controller.clearSearch,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF17392D),
                            ),
                          )
                        : const Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: Icon(
                              Icons.tune_rounded,
                              color: Color(0xFFBAC7C1),
                            ),
                          ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
