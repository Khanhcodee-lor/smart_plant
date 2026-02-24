import 'package:flutter/material.dart';

class NoEffectIconButton extends StatelessWidget {
  final Icon icon;
  final VoidCallback onPressed;

  const NoEffectIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: icon,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        splashFactory: NoSplash.splashFactory,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
    );
  }
}
