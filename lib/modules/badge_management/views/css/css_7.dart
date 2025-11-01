import 'package:flutter/material.dart';
import '../../../../common/constants.dart';
import '../../../../models/entities/badge_management/yith_badge.dart';

import '../helper.dart';

class YITHBadgeCSS7 extends StatelessWidget {
  const YITHBadgeCSS7({super.key, required this.badge, required this.child});
  final YITHBadge badge;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          color: badge.backgroundColor,
          padding: const EdgeInsets.fromLTRB(8, 3, 10, 3),
          margin: const EdgeInsets.only(left: 13),
          child: child,
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          width: 13,
          child: LayoutBuilder(
            builder: (_, BoxConstraints constraints) {
              var height = constraints.maxHeight;
              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                            width: 13,
                            color:
                                badge.backgroundColor ?? HexColor('#e73e08')),
                        bottom: BorderSide(
                            width: height / 2, color: Colors.transparent),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                            width: 13,
                            color:
                                badge.backgroundColor ?? HexColor('#e73e08')),
                        top: BorderSide(
                            width: height / 2, color: Colors.transparent),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        ),
        Positioned(
          bottom: -6,
          right: 0,
          child: SizedBox(
            width: 7,
            height: 6,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: const BorderSide(width: 2, color: Colors.transparent),
                  right: const BorderSide(width: 5, color: Colors.transparent),
                  top: BorderSide(
                      width: 6,
                      color: YITHBadgeHelper.darkColor(
                          badge.backgroundColor ?? HexColor('#e73e08'))),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
