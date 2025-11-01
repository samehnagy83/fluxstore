import 'package:flutter/material.dart';

import '../../app.dart';
import '../../widgets/common/flux_alert.dart';

/// Data class for bottom sheet action items.
///
/// Each action contains an icon, title, callback function, and optional destructive styling.
class BottomSheetAction {
  final IconData icon;
  final String title;
  final VoidCallback onPressed;
  final bool isDestructive;

  const BottomSheetAction({
    required this.icon,
    required this.title,
    required this.onPressed,
    this.isDestructive = false,
  });
}

/// This extension provides convenience methods to show different types of [FluxAlert] in a bottom sheet.
extension BottomSheetActionExtension on BuildContext {
  /// Shows a [FluxAlert] in a bottom sheet.
  ///
  /// The [dialog] parameter is the [FluxAlert] to be shown.
  /// Returns a [Future] that completes to the value (if any) that was passed
  /// to [Navigator.pop] when the dialog was closed.
  Future<bool?> showFluxBottomSheetAction(FluxAlert dialog) {
    return showDialog<bool>(
      context: this,
      builder: (context) => _WrapperBottomSheet(child: dialog),
    );
  }

  /// Shows a [FluxAlert] with text buttons in a bottom sheet.
  ///
  /// The [title], [body], [primaryAction], [secondaryAction], and [tertiaryAction] parameters are
  /// all optional and are displayed as text in the dialog.
  ///
  /// If [primaryAsDestructiveAction] is set to [true], the primary action button
  /// will be styled as a destructive action.
  ///
  /// If [useAppNavigator] is set to [true], the [App.fluxStoreNavigatorKey]
  /// will be used as the context for the bottom sheet.
  ///
  /// Returns a [Future] that completes when the dialog is dismissed.
  Future<bool> showFluxBottomSheetActionText({
    String? title,
    String? body,
    String? primaryAction,
    String? secondaryAction,
    String? tertiaryAction,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    VoidCallback? onTertiaryPressed,
    bool primaryAsDestructiveAction = false,
    bool useAppNavigator = true,
    Axis? directionButton,
  }) async {
    return await _commonModalBottomSheet<bool>(
          useAppNavigator: useAppNavigator,
          builder: (context) => _WrapperBottomSheet(
            child: FluxAlert.text(
              title: title,
              body: body,
              primaryAction: primaryAction,
              secondaryAction: secondaryAction,
              tertiaryAction: tertiaryAction,
              onPrimaryPressed: onPrimaryPressed,
              onSecondaryPressed: onSecondaryPressed,
              onTertiaryPressed: onTertiaryPressed,
              directionButton: directionButton,
              primaryAsDestructiveAction: primaryAsDestructiveAction,
            ),
          ),
        ) ??
        false;
  }

  /// Shows a [FluxAlert] with confirmation buttons in a bottom sheet.
  ///
  /// The [title], [body], and [tertiaryAction] parameters are optional and are displayed as text
  /// in the dialog.
  ///
  /// If [primaryAsDestructiveAction] is set to [true], the primary action
  /// button will be styled as a destructive action.
  ///
  /// If [useAppNavigator] is set to [true], the [App.fluxStoreNavigatorKey]
  /// will be used as the context for the bottom sheet.
  ///
  /// Returns a [Future] that completes to the value (if any) that was passed
  /// to [Navigator.pop] when the dialog was closed.
  Future<bool> showFluxBottomSheetActionConfirm({
    String? title,
    String? body,
    String? tertiaryAction,
    VoidCallback? onTertiaryPressed,
    Axis? directionButton,
    bool primaryAsDestructiveAction = false,
    bool useAppNavigator = false,
  }) async {
    return await _commonModalBottomSheet<bool>(
          useAppNavigator: useAppNavigator,
          builder: (context) => _WrapperBottomSheet(
            child: tertiaryAction != null
                ? FluxAlert.text(
                    title: title,
                    body: body,
                    primaryAction: null,
                    // Will use default "Yes"
                    secondaryAction: null,
                    // Will use default "No"
                    tertiaryAction: tertiaryAction,
                    onTertiaryPressed: onTertiaryPressed,
                    primaryAsDestructiveAction: primaryAsDestructiveAction,
                    directionButton: directionButton,
                  )
                : FluxAlert.confirm(
                    title: title,
                    body: body,
                    primaryAsDestructiveAction: primaryAsDestructiveAction,
                    directionButton: directionButton,
                  ),
          ),
        ) ??
        false;
  }

  /// Shows a modal bottom sheet with the specified builder.
  ///
  /// The [builder] parameter is a function that returns the widget to be shown
  /// in the bottom sheet.
  ///
  /// If [useAppNavigator] is set to [true], the [App.fluxStoreNavigatorKey]
  /// will be used as the context for the bottom sheet.
  ///
  /// Returns a [Future] that completes to the value (if any) that was passed
  /// to [Navigator.pop] when the dialog was closed.
  Future<T?> _commonModalBottomSheet<T>({
    required WidgetBuilder builder,
    required bool useAppNavigator,
  }) async {
    return showModalBottomSheet<T>(
      context:
          useAppNavigator ? App.fluxStoreNavigatorKey.currentContext! : this,
      backgroundColor: Theme.of(this).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: builder,
    );
  }

  /// Shows a bottom sheet with a list of actions.
  ///
  /// Each action can have an icon, title, callback, and destructive styling.
  /// Perfect for context menus with multiple options.
  ///
  /// The [actions] parameter is a list of [BottomSheetAction] items to display.
  /// If [useAppNavigator] is set to [true], the [App.fluxStoreNavigatorKey]
  /// will be used as the context for the bottom sheet.
  /// If [useDialogStyle] is set to [true], actions will be displayed as
  /// dialog-style buttons (clean, text-only) instead of list items with icons.
  ///
  /// Returns a [Future] that completes when the bottom sheet is dismissed.
  Future<void> showFluxBottomSheetActionList({
    List<BottomSheetAction> actions = const [],
    bool useAppNavigator = false,
    bool useDialogStyle = false,
  }) {
    return _commonModalBottomSheet<void>(
      useAppNavigator: useAppNavigator,
      builder: (context) => _WrapperBottomSheet(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: useDialogStyle
              ? _DialogStyleActionList(actions: actions)
              : _ListStyleActionList(actions: actions),
        ),
      ),
    );
  }
}

/// A widget that displays actions in dialog-style buttons (clean, text-only).
class _DialogStyleActionList extends StatelessWidget {
  const _DialogStyleActionList({required this.actions});

  final List<BottomSheetAction> actions;

  @override
  Widget build(BuildContext context) {
    // Single-pass categorization for better performance
    final destructiveActions = <BottomSheetAction>[];
    final normalActions = <BottomSheetAction>[];

    for (final action in actions) {
      if (action.isDestructive) {
        destructiveActions.add(action);
      } else {
        normalActions.add(action);
      }
    }

    // Use ListView to prevent overflow with many actions
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Add normal actions first
        ...normalActions
            .map((action) => _DialogStyleActionButton(action: action)),

        // Add divider if we have both types
        if (normalActions.isNotEmpty && destructiveActions.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(height: 1),
          ),

        // Add destructive actions
        ...destructiveActions
            .map((action) => _DialogStyleActionButton(action: action)),
      ],
    );
  }
}

/// A single dialog-style action button.
class _DialogStyleActionButton extends StatelessWidget {
  const _DialogStyleActionButton({required this.action});

  final BottomSheetAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      constraints:
          const BoxConstraints(minHeight: 48.0), // Accessibility compliance
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          action.onPressed();
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: action.isDestructive
                ? BorderSide.none
                : BorderSide(color: theme.dividerColor),
          ),
          backgroundColor: action.isDestructive
              ? theme.colorScheme.error
              : Colors.transparent,
        ),
        child: Text(
          action.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: action.isDestructive
                ? Colors.white
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// A widget that displays actions in list-style items (with icons).
class _ListStyleActionList extends StatelessWidget {
  const _ListStyleActionList({required this.actions});

  final List<BottomSheetAction> actions;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: actions
          .map((action) => _ListStyleActionItem(action: action))
          .toList(),
    );
  }
}

/// A single list-style action item.
class _ListStyleActionItem extends StatelessWidget {
  const _ListStyleActionItem({required this.action});

  final BottomSheetAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(
        action.icon,
        size: 24.0, // Material Design 3 standard
        color: action.isDestructive
            ? theme.colorScheme.error
            : theme.colorScheme.onSurface,
      ),
      title: Text(
        action.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: action.isDestructive
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface,
        ),
      ),
      horizontalTitleGap: 16.0,
      // Material Design 3 standard
      minVerticalPadding: 12.0,
      // Ensure 56dp minimum height
      onTap: () {
        Navigator.of(context).pop();
        action.onPressed();
      },
    );
  }
}

/// A wrapper widget for displaying content in a bottom sheet.
///
/// The [child] parameter is the widget to be displayed in the bottom sheet.
class _WrapperBottomSheet extends StatelessWidget {
  const _WrapperBottomSheet({
    required this.child,
  });

  final Widget child;

  /// Builds the [_WrapperBottomSheet] widget.
  ///
  /// The widget is displayed with a small grey bar at the top and the specified
  /// child widget below it.
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 50,
            height: 5,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
