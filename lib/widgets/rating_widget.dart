import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingWidget extends StatelessWidget {
  final double initialRating;
  final bool readOnly;
  final double size;
  final ValueChanged<double>? onRatingUpdate;

  const RatingWidget({
    super.key,
    this.initialRating = 0,
    this.readOnly = false,
    this.size = 20,
    this.onRatingUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: initialRating,
      minRating: 1,
      direction: Axis.horizontal,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: size,
      ignoreGestures: readOnly,
      itemPadding: const EdgeInsets.symmetric(horizontal: 1),
      itemBuilder: (context, _) => const Icon(
        Icons.star_rounded,
        color: Colors.amber,
      ),
      unratedColor: Colors.white.withValues(alpha: 0.15),
      onRatingUpdate: onRatingUpdate ?? (_) {},
    );
  }
}
