import 'package:flutter/material.dart';

import '../../../../models/index.dart';

class PhoneItem extends StatelessWidget {
  final Product item;
  final bool show;
  const PhoneItem({required this.item, required this.show});

  @override
  Widget build(BuildContext context) {
    if (item.phone == null || show == false) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        spacing: 5.0,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.phone, size: 15),
          Expanded(
            child: Text(
              item.phone.toString(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
