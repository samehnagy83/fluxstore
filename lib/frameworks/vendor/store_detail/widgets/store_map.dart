import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../common/constants.dart';
import '../../../../screens/base_screen.dart';
import '../../../../screens/common/google_map_mixin.dart';
import '../../../../services/services.dart';

class StoreMap extends StatefulWidget {
  final Store? store;
  final bool static;

  const StoreMap({this.store, this.static = true});

  @override
  BaseScreen<StoreMap> createState() => _StoreMapState();
}

class _StoreMapState extends BaseScreen<StoreMap> with GoogleMapMixin {
  GoogleMapController? pageController;
  Uri? renderMapURL;

  @override
  void afterFirstLayout(BuildContext context) {
    _buildUrl();
  }

  void _buildUrl() {
    final lat = widget.store!.lat ?? 0.0;
    final lng = widget.store!.long ?? 0.0;

    renderMapURL = Services().api.buildStaticMapUrl(
          lat: lat,
          lng: lng,
          styleParams: getMapStyleParams().cast<String>(),
        );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktop || kIsWeb) {
      return const SizedBox();
    }
    if (widget.store!.lat == null || widget.store!.long == null) {
      return const SizedBox();
    }

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:
                    Theme.of(context).primaryColorLight.withValueOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          if (renderMapURL != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Tools.launchMaps(
                  lat: widget.store?.lat,
                  long: widget.store?.long,
                  address: widget.store?.address,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: FluxImage(
                    imageUrl: renderMapURL.toString(),
                    fit: BoxFit.cover,
                    // width: double.infinity,
                    errorWidget: Center(
                      child: Text(
                        S.of(context).viewOnGoogleMaps,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: () => Tools.launchMaps(
                lat: widget.store?.lat,
                long: widget.store?.long,
                address: widget.store?.address,
              ),
              child: Container(
                color:
                    Theme.of(context).primaryColorLight.withValueOpacity(0.7),
                padding:
                    const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(width: 5),
                    Icon(
                      Icons.directions,
                      color: Theme.of(context).primaryColor,
                      size: 25,
                    ),
                    const SizedBox(
                      width: 5.0,
                    ),
                    Text(S.of(context).direction),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
