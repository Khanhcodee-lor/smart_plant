import 'package:app_iot/src/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

SnackBar buildDiseaseFeedbackSnackBar(String message, {bool isError = false}) {
  return SnackBar(
    content: Row(
      children: [
        Icon(
          isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(18, 0, 18, 92),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    duration: const Duration(milliseconds: 1800),
    dismissDirection: DismissDirection.horizontal,
    backgroundColor: isError ? AppColors.error : Colors.black.withOpacity(0.78),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

void showDiseaseFeedbackSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(buildDiseaseFeedbackSnackBar(message, isError: isError));
}
