import 'package:flutter/material.dart';

extension StringCasingExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String toUpperSnake() {
    if (isEmpty) return this;
    final exp = RegExp(r'(?<=[a-z])[A-Z]');
    return replaceAllMapped(exp, (m) => '_${m.group(0)}').toUpperCase().replaceAll(' ', '_');
  }
}

extension DateTimeExtensions on DateTime {
  String timeAgo() {
    final difference = DateTime.now().difference(this);
    if (difference.inDays > 8) {
      return '${this.year}-${this.month.toString().padLeft(2, '0')}-${this.day.toString().padLeft(2, '0')}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}

extension DoubleExtensions on double {
  // Placeholder for coordinate conversion if needed
  String toLatLng() => toStringAsFixed(6);
}

extension ColorExtensions on Color {
  Color withOpacityValue(double opacity) => withValues(alpha: opacity);
}

extension BuildContextExtensions on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
