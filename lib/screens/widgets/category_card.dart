import 'package:flutter/material.dart';

import '../../utils/ColorConstants.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: isSelected
              ? const Duration(milliseconds: 70)
              : const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF4FCEB),
                      Color(0xFFE4F7EC),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFF7FBF9),
                    ],
                  ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF9BD0AE)
                  : const Color(0xFFDCE8E1),
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF1B6B4A).withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: isSelected ? 18 : 10,
                offset: Offset(0, isSelected ? 8 : 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: isSelected
                    ? const Duration(milliseconds: 70)
                    : const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFC8E7D4)
                        : const Color(0xFFE6EFEB),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? ColorConstants.primaryDark.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: isSelected ? 12 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: ClipOval(
                    child: Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        "assets/permission/location.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 10.8,
                  height: 1.15,
                  color: const Color(0xFF17392D),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: isSelected
                    ? const Duration(milliseconds: 70)
                    : const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 9.2,
                  height: 1.15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? ColorConstants.primaryDark
                      : const Color(0xFF6E877C),
                ),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
