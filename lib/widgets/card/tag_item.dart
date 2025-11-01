import 'package:flutter/material.dart';

import '../../../../models/index.dart';

class TagItem extends StatelessWidget {
  final Product item;
  final bool hide;
  const TagItem({required this.item, required this.hide});

  @override
  Widget build(BuildContext context) {
    if (item.tagLine == null || hide == true) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        item.tagLine.toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
