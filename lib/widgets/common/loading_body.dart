import 'package:flutter/material.dart';

import '../../common/config.dart';
import '../../common/constants.dart';

class LoadingBody extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? backgroundColor;

  const LoadingBody({
    super.key,
    this.backgroundColor,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ??
        Theme.of(context).colorScheme.surface.withValueOpacity(0.4);
    return Stack(
      children: [
        child,
        Visibility(
          visible: isLoading,
          child: Center(
            child: Container(
              color: color,
              child: kLoadingWidget(context),
            ),
          ),
        )
      ],
    );
  }
}
