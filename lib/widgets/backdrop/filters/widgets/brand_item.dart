import 'package:flutter/material.dart';
import 'package:flux_ui/flux_ui.dart';

import '../../../../models/entities/brand.dart';
import 'container_filter.dart';

class BrandItem extends StatelessWidget {
  final Brand? brand;
  final void Function()? onTap;
  final bool isBrandNameShown;
  final bool isLogoCornerRounded;
  final bool isSelected;

  const BrandItem({
    this.brand,
    this.onTap,
    this.isBrandNameShown = true,
    this.isLogoCornerRounded = true,
    this.isSelected = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var primaryText = theme.primaryColor;
    var secondColor = theme.colorScheme.secondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ContainerFilter(
        isSelected: isSelected,
        child: SizedBox(
          height: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              brand?.image != null
                  ? ClipRRect(
                      borderRadius: isLogoCornerRounded
                          ? const BorderRadius.all(
                              Radius.circular(15.0),
                            )
                          : BorderRadius.zero,
                      child: FluxImage(
                        imageUrl: brand?.image ?? '',
                        width: 60.0,
                        height: 60.0,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const SizedBox(height: 60.0),
              const SizedBox(height: 5),
              isBrandNameShown
                  ? Expanded(
                      child: Text(
                        brand?.name ?? '',
                        maxLines: 2,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: isSelected
                                  ? primaryText
                                  : secondColor.withValues(alpha: 0.8),
                              // letterSpacing: 1.2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
