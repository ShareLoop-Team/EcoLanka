import 'package:flutter/material.dart';

import '../config/constants.dart';

/// Read-only star display, e.g. ★★★★☆ 4.2 (5)
class StarRating extends StatelessWidget {
  final double value;
  final int? count;
  final double size;

  const StarRating({super.key, required this.value, this.count, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            value >= i
                ? Icons.star_rounded
                : (value >= i - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
            size: size,
            color: AppColors.awardGold,
          ),
        if (count != null) ...[
          const SizedBox(width: 4),
          Text(
            count == 0 ? 'No reviews' : '${value.toStringAsFixed(1)} ($count)',
            style: TextStyle(fontSize: size * 0.75, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Tappable 1–5 star picker.
class StarRatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const StarRatingInput({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            iconSize: 40,
            onPressed: () => onChanged(i),
            icon: Icon(
              value >= i ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppColors.awardGold,
            ),
          ),
      ],
    );
  }
}
