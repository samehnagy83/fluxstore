import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../common/constants.dart';
import '../../models/app_model.dart';
import '../../modules/dynamic_layout/background/background.dart';
import '../../modules/dynamic_layout/config/app_config.dart';
import '../../widgets/home/index.dart';
import '../base_screen.dart';
import '../common/app_bar_mixin.dart';

class DynamicScreen extends StatefulWidget {
  final String? previewKey;
  final configs;

  const DynamicScreen({this.configs, this.previewKey});

  @override
  State<StatefulWidget> createState() {
    return DynamicScreenState();
  }
}

class DynamicScreenState extends BaseScreen<DynamicScreen>
    with AutomaticKeepAliveClientMixin<DynamicScreen>, AppBarMixin {
  static BuildContext? homeContext;

  static late BuildContext loadingContext;

  bool get emptyHorizontal => widget.configs['HorizonLayout']?.isEmpty ?? true;

  ValueNotifier<double> offsetNotifier = ValueNotifier(0);

  @override
  bool get wantKeepAlive => true;

  StreamSubscription? _sub;
  int? itemId;

  @override
  void dispose() {
    printLog('[Home] dispose');
    _sub?.cancel();
    super.dispose();
  }

  @override
  Future<void> afterFirstLayout(BuildContext context) async {
    homeContext = context;
  }

  static void showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        loadingContext = context;
        return Center(
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(5.0)),
            padding: const EdgeInsets.all(50.0),
            child: kLoadingWidget(context),
          ),
        );
      },
    );
  }

  static void hideLoading() {
    Navigator.of(loadingContext).pop();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    printLog('[Dynamic Screen] build');
    return Selector<AppModel, AppConfig?>(
      selector: (_, model) => model.appConfig,
      builder: (__, appConfig, child) {
        if (appConfig == null) {
          return kLoadingWidget(context);
        }

        final configs = widget.configs;

        if (configs is! Map || configs.isEmpty) {
          return const SizedBox();
        }

        final pageConfig = AppConfig.fromJson(configs);
        final isStickyHeader = appConfig.settings.stickyHeader;
        final backgroundConfig = pageConfig.background;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              if (backgroundConfig?.isScrollable != true) {
                return false;
              }
              if (scrollNotification is ScrollUpdateNotification) {
                final value = scrollNotification.metrics.pixels;
                if (value < 0) {
                  offsetNotifier.value = 0;
                } else {
                  offsetNotifier.value = value;
                }
              }
              return true;
            },
            child: Stack(
              children: <Widget>[
                if (backgroundConfig != null)
                  ValueListenableBuilder<double>(
                    valueListenable: offsetNotifier,
                    builder: (context, offset, child) {
                      return Positioned(
                        top: -offset,
                        left: 0,
                        right: 0,
                        child: isStickyHeader
                            ? SafeArea(
                                child: HomeBackground(config: backgroundConfig),
                              )
                            : HomeBackground(config: backgroundConfig),
                      );
                    },
                  ),

                if (!emptyHorizontal ||
                    (configs['VerticalLayout']?.isNotEmpty ?? false))
                  HomeLayout(
                      isPinAppBar: isStickyHeader,
                      isShowAppbar: emptyHorizontal
                          ? false
                          : configs['HorizonLayout'][0]['layout'] == 'logo',
                      showNewAppBar:
                          appConfig.appBar?.shouldShowOn(RouteList.dynamic) ??
                              false,
                      configs: configs),
                // Remove `WrapStatusBar` because we already have `SafeArea`
                // inside `HomeLayout`
                // const WrapStatusBar(),
              ],
            ),
          ),
        );
      },
    );
  }
}
