import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:inspireui/inspireui.dart';
import 'package:provider/provider.dart';

import '../../common/events.dart';
import '../../common/extensions/bottom_sheet_action_ext.dart';
import '../../common/extensions/dialog_ext.dart';
import '../../common/tools/flash.dart';
import '../../common/tools/navigate_tools.dart';
import '../../models/address_management_model.dart';
import '../../models/entities/address.dart';
import '../../models/user_model.dart';
import 'add_address_screen.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() =>
      _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  StreamSubscription<EventLoggedIn>? _loginSubscription;

  @override
  void initState() {
    super.initState();

    // Listen for login events to refresh addresses
    _loginSubscription = eventBus.on<EventLoggedIn>().listen((_) {
      _onUserLoggedIn();
    });

    // Fetch addresses when screen loads
    WidgetsBinding.instance.endOfFrame.then((_) {
      final userModel = context.read<UserModel>();
      if (userModel.loggedIn) {
        context.read<AddressManagementModel>().fetchCustomerAddresses();
      }
    });
  }

  @override
  void dispose() {
    _loginSubscription?.cancel();
    super.dispose();
  }

  /// Handle user login event - fetch addresses when user logs in
  void _onUserLoggedIn() {
    if (mounted) {
      final userModel = context.read<UserModel>();
      if (userModel.loggedIn) {
        context.read<AddressManagementModel>().fetchCustomerAddresses();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          S.of(context).address,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        actions: [
          Selector<UserModel, bool>(
            selector: (context, userModel) => userModel.loggedIn,
            builder: (context, loggedIn, child) {
              if (loggedIn) {
                return IconButton(
                  onPressed: _onAddAddressPressed,
                  icon: Icon(
                    CupertinoIcons.add,
                    color: colorScheme.primary,
                  ),
                  tooltip: S.of(context).addNewAddress,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<AddressManagementModel>(
        builder: (_, addressNotifier, child) {
          if (addressNotifier.isLoading) {
            return const _AddressManagementSkeleton();
          }

          if (addressNotifier.errorMessage != null) {
            return Container(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Colors.red[400],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        addressNotifier.errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () =>
                            addressNotifier.fetchCustomerAddresses(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(S.of(context).retry),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final addresses = addressNotifier.addresses;
          final defaultAddress = addressNotifier.defaultAddress;

          // Create a combined list with default address first
          final allAddresses = <Address>[];
          if (defaultAddress != null) {
            allAddresses.add(defaultAddress);
          }
          // Add non-default addresses
          for (final address in addresses) {
            if (defaultAddress == null ||
                !address.compareFullInfo(defaultAddress)) {
              allAddresses.add(address);
            }
          }

          if (allAddresses.isEmpty) {
            return Selector<UserModel, bool>(
              selector: (context, userModel) => userModel.loggedIn,
              builder: (context, isLoggedIn, child) {
                final config = _getEmptyStateConfig(context, isLoggedIn);
                return _EmptyStateWidget(config: config);
              },
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 100.0),
            itemCount: allAddresses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12.0),
            itemBuilder: (context, index) {
              final address = allAddresses[index];
              final isDefault = defaultAddress != null &&
                  address.compareFullInfo(defaultAddress);

              return _AddressCard(
                address: address,
                isDefault: isDefault,
                totalAddresses: allAddresses.length,
                onShowActions: _onShowAddressActions,
                onTap: () => _onEditAddressPressed(address),
              );
            },
          );
        },
      ),
      floatingActionButton: Selector<UserModel, bool>(
        selector: (context, userModel) => userModel.loggedIn,
        builder: (context, loggedIn, child) {
          if (loggedIn) {
            return Container(
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: FloatingActionButton(
                onPressed: _onAddAddressPressed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Icon(
                  Icons.add_rounded,
                  color: colorScheme.onPrimary,
                  size: 28,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Handle add address button press
  void _onAddAddressPressed() {
    _showAddAddressDialog();
  }

  /// Handle address actions (edit, delete, set default)
  void _onShowAddressActions(
      Address address, bool isDefault, int totalAddresses) {
    final actions = <BottomSheetAction>[
      // Edit action - always show
      BottomSheetAction(
        icon: Icons.edit,
        title: S.of(context).edit,
        onPressed: () => _onEditAddressPressed(address),
      ),
      // Set as Default - only if not default
      if (!isDefault)
        BottomSheetAction(
          icon: Icons.star,
          title: S.of(context).setAsDefault,
          onPressed: () => _onSetDefaultPressed(address),
        ),
      // Delete - only if more than 1 address or not default
      if (totalAddresses > 1 || !isDefault)
        BottomSheetAction(
          icon: Icons.delete,
          title: S.of(context).delete,
          onPressed: () => _onDeleteAddressPressed(address),
          isDestructive: true,
        ),
    ];

    context.showFluxBottomSheetActionList(
      actions: actions,
      useDialogStyle: true,
    );
  }

  /// Handle edit address button press
  void _onEditAddressPressed(Address address) {
    _showEditAddressDialog(address);
  }

  /// Handle set default button press
  void _onSetDefaultPressed(Address address) async {
    final addressNotifier = context.read<AddressManagementModel>();

    // Find the index of the address in the list
    final addressIndex = addressNotifier.addresses.indexWhere(
      (addr) => addr.compareFullInfo(address),
    );

    if (addressIndex == -1) {
      await FlashHelper.errorMessage(context,
          message: S.of(context).addressNotFound);
      return;
    }

    try {
      final success = await addressNotifier.setDefaultAddress(addressIndex);

      if (success) {
        await FlashHelper.message(context,
            message: S.of(context).defaultAddressUpdatedSuccessfully,
            isError: false);

        // Refresh the address list to get updated default address
        await addressNotifier.fetchCustomerAddresses();
      } else {
        await FlashHelper.errorMessage(context,
            message: addressNotifier.errorMessage ??
                S.of(context).failedToUpdateDefaultAddress);
      }
    } catch (e) {
      await FlashHelper.errorMessage(context,
          message: '${S.of(context).errorPrefix}: ${e.toString()}');
    }
  }

  /// Handle delete address button press
  void _onDeleteAddressPressed(Address address) async {
    final confirmed = await context.showFluxDialogConfirm(
      title: S.of(context).delete,
      body: S.of(context).confirmDeleteItem,
      primaryAsDestructiveAction: true,
    );

    if (confirmed) {
      _deleteAddress(address);
    }
  }

  void _showAddAddressDialog() {
    // Lưu reference đến AddressManagementModel trước khi navigate
    final addressNotifier = context.read<AddressManagementModel>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: addressNotifier, // ✅ Sử dụng saved reference
          child: AddAddressScreen(
            arguments: AddAddressArguments(
              onSaved: (address) async {
                // Refresh the address list after adding
                await addressNotifier.fetchCustomerAddresses();
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showEditAddressDialog(Address address) {
    // Lưu reference đến AddressManagementModel trước khi navigate
    final addressNotifier = context.read<AddressManagementModel>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: addressNotifier, // ✅ Sử dụng saved reference
          child: AddAddressScreen(
            arguments: AddAddressArguments(
              address: address, // Pass address for editing
              onSaved: (updatedAddress) async {
                // Refresh the address list after editing
                await addressNotifier.fetchCustomerAddresses();
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Get configuration for empty state based on user login status
  _EmptyStateConfig _getEmptyStateConfig(
      BuildContext context, bool isLoggedIn) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoggedIn) {
      return _EmptyStateConfig(
        icon: Icons.location_off_rounded,
        iconColor: colorScheme.primary,
        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
        title: S.of(context).noAddressesFound,
        subtitle: S.of(context).pleaseAddAddressFirst,
        buttonText: S.of(context).addNewAddress,
        buttonIcon: Icons.add_location_rounded,
        onButtonPressed: _onAddAddressPressed,
      );
    }

    return _EmptyStateConfig(
      icon: Icons.person_off_rounded,
      iconColor: colorScheme.error,
      backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
      title: S.of(context).youNeedToLoginToSeeAddresses,
      subtitle: S.of(context).loginToYourAccount,
      buttonText: S.of(context).login,
      buttonIcon: Icons.login_rounded,
      onButtonPressed: () => NavigateTools.navigateToLogin(context),
    );
  }

  void _deleteAddress(Address address) async {
    final addressNotifier = context.read<AddressManagementModel>();

    // Find the index of the address in the list
    final addressIndex = addressNotifier.addresses.indexWhere(
      (addr) => addr.compareFullInfo(address),
    );

    if (addressIndex == -1) {
      await FlashHelper.errorMessage(context,
          message: S.of(context).addressNotFound);
      return;
    }

    try {
      final success = await addressNotifier.deleteAddress(addressIndex);

      if (success) {
        await FlashHelper.message(context,
            message: S.of(context).updateSuccess, isError: false);
      } else {
        await FlashHelper.errorMessage(context,
            message:
                addressNotifier.errorMessage ?? S.of(context).unexpectedError);
      }
    } catch (e) {
      await FlashHelper.errorMessage(context,
          message: '${S.of(context).errorPrefix}: ${e.toString()}');
    }
  }
}

/// Configuration data class for empty state widget
class _EmptyStateConfig {
  const _EmptyStateConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.buttonIcon,
    required this.onButtonPressed,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final String buttonText;
  final IconData buttonIcon;
  final VoidCallback onButtonPressed;
}

/// A reusable widget for displaying empty state with consistent styling
class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget({
    required this.config,
  });

  final _EmptyStateConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(context),
              const SizedBox(height: 32),
              _buildTitle(context),
              const SizedBox(height: 16),
              _buildSubtitle(context),
              const SizedBox(height: 40),
              _buildActionButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        config.icon,
        size: 72,
        color: config.iconColor,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      config.title,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      config.subtitle,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: config.onButtonPressed,
      icon: Icon(config.buttonIcon),
      label: Text(config.buttonText),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
      ),
    );
  }
}

/// A widget that displays an address card with enhanced Material Design styling.
class _AddressCard extends StatefulWidget {
  const _AddressCard({
    required this.address,
    required this.isDefault,
    required this.totalAddresses,
    required this.onShowActions,
    this.onTap,
  });

  final Address address;
  final bool isDefault;
  final int totalAddresses;
  final void Function(Address address, bool isDefault, int totalAddresses)
      onShowActions;
  final VoidCallback? onTap;

  @override
  State<_AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends State<_AddressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            onTapDown: (_) {
              _animationController.forward();
            },
            onTapUp: (_) {
              _animationController.reverse();
            },
            onTapCancel: () {
              _animationController.reverse();
            },
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isDefault
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.3),
                  width: widget.isDefault ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAddressTitle(context),
                    const SizedBox(height: 12.0),
                    _buildAddressSubtitle(context),
                    if (widget.isDefault) ...[
                      const SizedBox(height: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: colorScheme.onPrimary,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              S.of(context).defaultLabel,
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build address title with name and default badge
  Widget _buildAddressTitle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            '${widget.address.firstName ?? ''} ${widget.address.lastName ?? ''}'
                .trim(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => widget.onShowActions(
                widget.address, widget.isDefault, widget.totalAddresses),
            icon: Icon(
              Icons.more_vert_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            iconSize: 20.0,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: S.of(context).options,
          ),
        ),
      ],
    );
  }

  /// Build address subtitle with details and phone
  Widget _buildAddressSubtitle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address details with location icon
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _formatAddress(widget.address),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        if (widget.address.phoneNumber?.isNotEmpty == true) ...[
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.address.phoneNumber!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatAddress(Address address) {
    final parts = <String>[];

    if (address.street?.isNotEmpty == true) parts.add(address.street!);
    if (address.apartment?.isNotEmpty == true) parts.add(address.apartment!);
    if (address.city?.isNotEmpty == true) parts.add(address.city!);
    if (address.state?.isNotEmpty == true) parts.add(address.state!);
    if (address.zipCode?.isNotEmpty == true) parts.add(address.zipCode!);
    if (address.country?.isNotEmpty == true) parts.add(address.country!);

    return parts.join(', ');
  }
}

// ============================================================================
// SKELETON WIDGETS
// ============================================================================

/// A skeleton widget that mimics the structure of _AddressCard
/// Used during loading states to prevent layout shifts
class _AddressCardSkeleton extends StatelessWidget {
  const _AddressCardSkeleton({
    this.showDefaultBadge = false,
  });

  final bool showDefaultBadge;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleSkeleton(context),
            const SizedBox(height: 8.0),
            _buildSubtitleSkeleton(context),
          ],
        ),
      ),
    );
  }

  /// Build skeleton for address title (name + default badge)
  Widget _buildTitleSkeleton(BuildContext context) {
    return Row(
      children: [
        // Person icon skeleton
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),

        // Name skeleton - using Expanded to match original layout
        const Expanded(
          child: Skeleton(
            height: 18,
            width: 120,
            cornerRadius: 4,
          ),
        ),

        const SizedBox(width: 16),

        // More button skeleton
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              Skeleton(
                width: 4,
                height: 4,
                cornerRadius: 12,
              ),
              SizedBox(height: 2),
              Skeleton(
                width: 4,
                height: 4,
                cornerRadius: 12,
              ),
              SizedBox(height: 2),
              Skeleton(
                width: 4,
                height: 4,
                cornerRadius: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build skeleton for address subtitle (address details + phone)
  Widget _buildSubtitleSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address details skeleton with icon
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(
                    height: 14,
                    width: 200,
                    cornerRadius: 4,
                  ),
                  SizedBox(height: 4),
                  Skeleton(
                    height: 14,
                    width: 150,
                    cornerRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Phone number skeleton with icon
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            const Skeleton(
              height: 14,
              width: 100,
              cornerRadius: 4,
            ),
          ],
        ),
        if (showDefaultBadge) ...[
          const SizedBox(height: 8.0),
          // Default badge skeleton with proper styling
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 6.0,
            ),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Skeleton(
              height: 12,
              width: 50,
              cornerRadius: 4,
            ),
          ),
        ],
      ],
    );
  }
}

/// A comprehensive skeleton widget for AddressManagementScreen
/// Mimics the exact flat list layout structure to prevent layout shifts during loading
class _AddressManagementSkeleton extends StatelessWidget {
  const _AddressManagementSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 100.0),
        itemCount: 6, // Show 6 skeleton cards (1 default + 3 others)
        separatorBuilder: (_, __) => const SizedBox(height: 12.0),
        itemBuilder: (context, index) {
          return _AddressCardSkeleton(
            showDefaultBadge: index == 0, // First item shows default badge
          );
        },
      ),
    );
  }
}
