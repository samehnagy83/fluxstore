import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:inspireui/inspireui.dart';
import 'package:provider/provider.dart';

import '../../common/events.dart';
import '../../common/extensions/bottom_sheet_action_ext.dart';
import '../../common/extensions/dialog_ext.dart';
import '../../common/tools/navigate_tools.dart';
import '../../models/address_management_model.dart';
import '../../models/entities/address.dart';
import '../../models/user_model.dart';
import 'add_address_screen.dart';

class AddressSelectionScreen extends StatefulWidget {
  final Address? currentAddress;

  const AddressSelectionScreen({super.key, this.currentAddress});

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  Address? selectedAddress;
  StreamSubscription<EventLoggedIn>? _loginSubscription;

  @override
  void initState() {
    super.initState();
    selectedAddress = widget.currentAddress;

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
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).selectAddress),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          actions: [
            Selector<UserModel, bool>(
              selector: (context, userModel) => userModel.loggedIn,
              builder: (context, loggedIn, child) {
                if (loggedIn) {
                  return IconButton(
                    onPressed: () => _showAddAddressDialog(context),
                    icon: const Icon(CupertinoIcons.add),
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
              return const _AddressSelectionSkeleton();
            }

            if (addressNotifier.errorMessage != null) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.8),
                    ],
                  ),
                ),
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

            if (addresses.isEmpty && defaultAddress == null) {
              return Selector<UserModel, bool>(
                selector: (context, userModel) => userModel.loggedIn,
                builder: (context, isLoggedIn, child) {
                  final config = _getEmptyStateConfig(context, isLoggedIn);
                  return _EmptyStateWidget(config: config);
                },
              );
            }

            return RadioGroup<Address>(
              groupValue: selectedAddress,
              onChanged: (value) {
                setState(() {
                  selectedAddress = value;
                });
              },
              child: Column(
                children: [
                  // Main content with addresses
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        // Default Address Section
                        if (defaultAddress != null) ...[
                          SliverToBoxAdapter(
                            child: Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerLowest,
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    S.of(context).defaultAddress,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 12.0),
                                  _AddressCard(
                                    address: defaultAddress,
                                    isDefault: true,
                                    isSelected: selectedAddress
                                            ?.compareFullInfo(defaultAddress) ==
                                        true,
                                    onTap: () {
                                      setState(() {
                                        selectedAddress = defaultAddress;
                                      });
                                    },
                                    totalAddresses: addresses.length + 1,
                                    onShowActions: _showAddressActions,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Visual separator
                          SliverToBoxAdapter(
                            child: Container(
                              height: 8.0,
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                        ],

                        // Other Addresses Section
                        if (addresses.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16.0, 16.0, 16.0, 8.0),
                              child: Text(
                                addresses.length == 1 && defaultAddress != null
                                    ? S.of(context).otherAddress
                                    : S.of(context).savedAddresses,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final address = addresses[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: _AddressCard(
                                      address: address,
                                      isDefault: false,
                                      isSelected: selectedAddress
                                              ?.compareFullInfo(address) ==
                                          true,
                                      onTap: () {
                                        setState(() {
                                          selectedAddress = address;
                                        });
                                      },
                                      totalAddresses: addresses.length +
                                          (defaultAddress != null ? 1 : 0),
                                      onShowActions: _showAddressActions,
                                    ),
                                  );
                                },
                                childCount: addresses.length,
                              ),
                            ),
                          ),
                        ],

                        // Bottom padding for button clearance
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 100.0),
                        ),
                      ],
                    ),
                  ),

                  // Fixed bottom button with improved styling
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: _ConfirmationButton(
                      isEnabled: selectedAddress != null,
                      onConfirm: () {
                        // Return the selected address as result
                        Navigator.of(context).pop(selectedAddress);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ));
  }

  void _showAddressActions(
      Address address, bool isDefault, int totalAddresses) {
    final actions = <BottomSheetAction>[
      // Edit action - always show
      BottomSheetAction(
        icon: Icons.edit,
        title: S.of(context).edit,
        onPressed: () => _showEditAddressDialog(context, address),
      ),
      // Set as Default - only if not default
      if (!isDefault)
        BottomSheetAction(
          icon: Icons.star,
          title: S.of(context).setAsDefault,
          onPressed: () => _setDefaultAddress(address),
        ),
      // Delete - only if more than 1 address or not default
      if (totalAddresses > 1 || !isDefault)
        BottomSheetAction(
          icon: Icons.delete,
          title: S.of(context).delete,
          onPressed: () => _showDeleteConfirmation(address),
          isDestructive: true,
        ),
    ];

    context.showFluxBottomSheetActionList(
      actions: actions,
      useDialogStyle: true, // Test new dialog style
    );
  }

  void _setDefaultAddress(Address address) async {
    final addressNotifier = context.read<AddressManagementModel>();

    // Find the index of the address in the list
    final addressIndex = addressNotifier.addresses.indexWhere(
      (addr) => addr.compareFullInfo(address),
    );

    if (addressIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).addressNotFound),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final success = await addressNotifier.setDefaultAddress(addressIndex);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).defaultAddressUpdatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the address list to get updated default address
        await addressNotifier.fetchCustomerAddresses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(addressNotifier.errorMessage ??
                S.of(context).failedToUpdateDefaultAddress),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.of(context).errorPrefix}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(Address address) async {
    final confirmed = await context.showFluxDialogConfirm(
      title: S.of(context).delete,
      body: S.of(context).confirmDeleteItem,
      primaryAsDestructiveAction: true,
    );

    if (confirmed) {
      _deleteAddress(address);
    }
  }

  void _deleteAddress(Address address) async {
    final addressNotifier = context.read<AddressManagementModel>();

    // Find the index of the address in the list
    final addressIndex = addressNotifier.addresses.indexWhere(
      (addr) => addr.compareFullInfo(address),
    );

    if (addressIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).addressNotFound),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final success = await addressNotifier.deleteAddress(addressIndex);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).updateSuccess),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                addressNotifier.errorMessage ?? S.of(context).unexpectedError),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.of(context).errorPrefix}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditAddressDialog(BuildContext context, Address address) {
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

  void _showAddAddressDialog(BuildContext context) {
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
        onButtonPressed: () => _showAddAddressDialog(context),
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
    return Center(
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

/// A widget that displays an address card with Material Design selection pattern.
class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isDefault,
    required this.isSelected,
    required this.onTap,
    required this.totalAddresses,
    required this.onShowActions,
  });

  final Address address;
  final bool isDefault;
  final bool isSelected;
  final VoidCallback onTap;
  final int totalAddresses;
  final void Function(Address address, bool isDefault, int totalAddresses)
      onShowActions;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 2 : 1, // Subtle elevation difference
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      // Use M3 surface tint for selected state
      surfaceTintColor: isSelected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
          : null,
      child: RadioListTile<Address>(
        value: address,
        // groupValue: isSelected ? address : null,
        // onChanged: (_) => onTap(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        activeColor: Theme.of(context).colorScheme.primary,
        title: _buildAddressTitle(context),
        subtitle: _buildAddressSubtitle(context),
        secondary: IconButton(
          onPressed: () => onShowActions(address, isDefault, totalAddresses),
          icon: const Icon(Icons.more_vert),
          iconSize: 24.0,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          tooltip: S.of(context).options,
        ),
        selected: isSelected,
        selectedTileColor: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.1),
      ),
    );
  }

  /// Build address title with name and default badge
  Widget _buildAddressTitle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${address.firstName ?? ''} ${address.lastName ?? ''}'.trim(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (isDefault) ...[
          const SizedBox(width: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0, // Slightly larger for better visibility
              vertical: 6.0, // More vertical padding
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius:
                  BorderRadius.circular(16), // More rounded for modern look
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              S.of(context).defaultLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Build address subtitle with details and phone
  Widget _buildAddressSubtitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4.0),
        Text(
          _formatAddress(address),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
        ),
        if (address.phoneNumber?.isNotEmpty == true) ...[
          const SizedBox(height: 2.0),
          Text(
            address.phoneNumber!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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

/// A widget that displays the Material Design confirmation button for address selection.
class _ConfirmationButton extends StatelessWidget {
  const _ConfirmationButton({
    required this.isEnabled,
    required this.onConfirm,
  });

  final bool isEnabled;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(16.0), // 16dp M3 safe area padding
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isEnabled ? onConfirm : null,
          icon: const Icon(Icons.check),
          label: Text(S.of(context).select),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            backgroundColor: isEnabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: isEnabled
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
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
      child: _buildSkeletonContent(context),
    );
  }

  Widget _buildSkeletonContent(BuildContext context) {
    return ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        leading: const Skeleton(
          width: 20,
          height: 20,
          cornerRadius: 10,
        ),
        title: _buildTitleSkeleton(context),
        subtitle: _buildSubtitleSkeleton(context),
        // Create Skeleton as Icon(Icons.more_vert)
        trailing: const Column(
          children: [
            Skeleton(
              width: 6,
              height: 6,
              cornerRadius: 12,
            ),
            SizedBox(height: 2),
            Skeleton(
              width: 6,
              height: 6,
              cornerRadius: 12,
            ),
            SizedBox(height: 2),
            Skeleton(
              width: 6,
              height: 6,
              cornerRadius: 12,
            ),
          ],
        ));
  }

  /// Build skeleton for address title (name + default badge)
  Widget _buildTitleSkeleton(BuildContext context) {
    return Row(
      children: [
        // Name skeleton - using Expanded to match original layout
        const Expanded(
          child: Skeleton(
            height: 18,
            width: 120,
            cornerRadius: 4,
          ),
        ),

        if (showDefaultBadge) ...[
          const SizedBox(width: 8.0),
          // Default badge skeleton with proper styling
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 6.0,
            ),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Skeleton(
              height: 11,
              width: 50,
              cornerRadius: 4,
            ),
          ),
        ],
      ],
    );
  }

  /// Build skeleton for address subtitle (address details + phone)
  Widget _buildSubtitleSkeleton(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Address details skeleton - 2 lines
        SizedBox(height: 8),
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
        SizedBox(height: 4),

        // Phone number skeleton
        Skeleton(
          height: 14,
          width: 100,
          cornerRadius: 4,
        ),
      ],
    );
  }
}

/// A comprehensive skeleton widget for AddressSelectionScreen
/// Mimics the exact layout structure to prevent layout shifts during loading
class _AddressSelectionSkeleton extends StatelessWidget {
  const _AddressSelectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main content with addresses
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Default Address Section
              SliverToBoxAdapter(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeaderSkeleton(context),
                      const SizedBox(height: 12.0),
                      const _AddressCardSkeleton(showDefaultBadge: true),
                    ],
                  ),
                ),
              ),

              // Visual separator
              SliverToBoxAdapter(
                child: Container(
                  height: 8.0,
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.3),
                ),
              ),

              // Other Addresses Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: _buildSectionHeaderSkeleton(context),
                ),
              ),

              // Other addresses list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: _AddressCardSkeleton(showDefaultBadge: false),
                      );
                    },
                    childCount: 6, // Show 2 skeleton cards for other addresses
                  ),
                ),
              ),

              // Bottom padding for button clearance
              const SliverToBoxAdapter(
                child: SizedBox(height: 100.0),
              ),
            ],
          ),
        ),

        // Fixed bottom button skeleton
        _buildBottomButtonSkeleton(context),
      ],
    );
  }

  /// Build skeleton for section headers (Default Address, Saved Addresses)
  Widget _buildSectionHeaderSkeleton(BuildContext context) {
    return const Skeleton(
      height: 24,
      width: 150,
      cornerRadius: 4,
    );
  }

  /// Build skeleton for the bottom confirmation button
  Widget _buildBottomButtonSkeleton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        minimum: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Skeleton(
              height: 48,
              width: double.infinity,
              cornerRadius: 12,
            ),
          ),
        ),
      ),
    );
  }
}
