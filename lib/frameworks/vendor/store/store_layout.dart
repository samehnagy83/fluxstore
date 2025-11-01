import 'dart:async';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import '../../../../models/index.dart' show AppModel;
import '../../../common/constants.dart';
import '../../../common/events.dart';
import '../../../models/vendor/store_model.dart';
import '../../../routes/flux_navigate.dart';
import '../../../screens/base_screen.dart';
import '../../../screens/search/widgets/search_box.dart';
import './layouts/card.dart';
import './layouts/column.dart';
import './layouts/grid.dart';

class StoreLayout extends StatefulWidget {
  const StoreLayout({super.key});

  @override
  BaseScreen<StoreLayout> createState() => _StoresState();
}

class _StoresState extends BaseScreen<StoreLayout> {
  String _currentSearchName = '';
  late StoreModel storeModel;
  StreamSubscription? _subAppCookieExpiry;
  FocusNode? _focusNode;
  late StreamSubscription<bool> _keyboardSubscription;

  Future<void> _requestLocationPermission() async {
    final location = Location();

    /// ask location permission
    var isGranted = await location.hasPermission();
    if (isGranted == PermissionStatus.denied) {
      isGranted = await location.requestPermission();
      if (isGranted != PermissionStatus.granted) {
        return;
      }
    }

    /// ask location service
    var isAllowService = await location.serviceEnabled();
    if (!isAllowService) {
      isAllowService = await location.requestService();
      if (!isAllowService) {
        return;
      }
    }

    unawaited(FluxNavigate.pushNamed(
      RouteList.map,
      context: context,
    ));
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _keyboardSubscription =
        KeyboardVisibilityController().onChange.listen((bool visible) {
      if (!visible) {
        _focusNode?.unfocus();
      }
    });
  }

  @override
  void afterFirstLayout(BuildContext context) {
    storeModel = Provider.of<StoreModel>(context, listen: false);
    storeModel.refreshStore();

    _subAppCookieExpiry = eventBus.on<EventExpiredCookie>().listen((event) {
      storeModel.refreshStore();
    });
  }

  @override
  void dispose() {
    _subAppCookieExpiry?.cancel();
    _focusNode?.dispose();
    _keyboardSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appModel = Provider.of<AppModel>(context);
    final vendorLayout = appModel.vendorLayout;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SearchBox(
                showCancelButton: false,
                focusNode: _focusNode,
                showQRCode: false,
                onChanged: (val) {
                  EasyDebounce.debounce(
                      'searchStoreScreen', const Duration(milliseconds: 300),
                      () {
                    setState(() {
                      _currentSearchName = val;
                    });
                    storeModel.loadStore(name: _currentSearchName);
                  });
                },
                onCancel: () {
                  setState(() {
                    _currentSearchName = '';
                  });
                  storeModel.loadStore(name: _currentSearchName);
                },
              ),
            ),
            GestureDetector(
              onTap: _requestLocationPermission,
              child: Tooltip(
                message: S.of(context).viewOnGoogleMaps,
                child: Icon(
                  Icons.place,
                  size: 26,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: renderStores(vendorLayout),
        ),
      ],
    );
  }

  Widget renderStores(String? layout) {
    switch (layout) {
      case 'column':
        return ColumnStores(searchName: _currentSearchName);
      case 'grid':
        return GridStores(searchName: _currentSearchName);
      case 'card':
      default:
        return CardStores(searchName: _currentSearchName);
    }
  }
}
