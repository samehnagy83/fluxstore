import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';

import '../../../common/constants.dart';
import '../../../screens/common/app_bar_mixin.dart';
import '../../../services/services.dart';
import 'store_layout.dart';

class VendorCategoriesScreen extends StatefulWidget {
  final String? categoryLayout;
  final bool enableParallax;
  final double? parallaxImageRatio;

  const VendorCategoriesScreen({
    Key key = const Key('category'),
    this.categoryLayout,
    this.enableParallax = false,
    this.parallaxImageRatio,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CategoriesScreenState();
  }
}

class CategoriesScreenState extends State<VendorCategoriesScreen>
    with AutomaticKeepAliveClientMixin, AppBarMixin {
  @override
  bool get wantKeepAlive => true;

  final _pageController = PageController(initialPage: 2);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.jumpToPage(0);
    });
    screenScrollController = _scrollController;
  }

  void _onChangeTab(value) {
    _pageController.animateToPage(
      value!,
      duration: const Duration(milliseconds: 250),
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return renderScaffold(
      resizeToAvoidBottomInset: false,
      routeName: RouteList.vendorCategory,
      backgroundColor: Theme.of(context).colorScheme.surface,
      secondAppBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 250,
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                return CupertinoSlidingSegmentedControl<int>(
                  backgroundColor: Theme.of(context).primaryColorLight,
                  thumbColor: Theme.of(context).colorScheme.surface,
                  children: {
                    0: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        S.of(context).stores.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.secondary,
                          fontFamily: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.fontFamily,
                        ),
                      ),
                    ),
                    1: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        S.of(context).categories.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.secondary,
                          fontFamily: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.fontFamily,
                        ),
                      ),
                    ),
                  },
                  onValueChanged: _onChangeTab,
                  groupValue: _pageController.hasClients
                      ? (_pageController.page?.round() ?? 0)
                      : 0,
                );
              },
            ),
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              allowImplicitScrolling: true,
              children: [
                const StoreLayout(),
                renderCategories(
                  widget.categoryLayout,
                  widget.enableParallax,
                  widget.parallaxImageRatio,
                  _scrollController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget renderCategories(
      String? categoryLayout, bool enableParallax, double? parallaxImageRatio,
      [ScrollController? scrollController]) {
    return Services().widget.renderCategoryLayout(
          layout: categoryLayout,
          enableParallax: enableParallax,
          parallaxImageRatio: parallaxImageRatio,
          scrollController: scrollController,
        );
  }
}
