import 'package:flutter/material.dart';

class CommonSafeArea extends StatelessWidget {
  const CommonSafeArea({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: child,
    );
  }
}
