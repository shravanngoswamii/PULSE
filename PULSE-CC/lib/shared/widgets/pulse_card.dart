import 'package:flutter/material.dart';

class PulseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final EdgeInsets? margin;

  const PulseCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Padding(
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: cardContent,
      );
    }

    return Card(
      margin: margin,
      child: cardContent,
    );
  }
}
