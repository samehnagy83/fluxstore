import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:inspireui/inspireui.dart';
import 'package:provider/provider.dart';

import '../../common/config/models/address_field_config.dart';
import '../../common/tools/flash.dart';
import '../../models/address_management_model.dart';
import '../../models/entities/address.dart';
import '../../services/index.dart';
import '../../widgets/common/loading_body.dart';
import 'managers/address_form_manager.dart';
import 'widgets/address_form_field.dart';
import 'widgets/address_save_button.dart';
import 'widgets/country_picker_field.dart';

class AddAddressArguments {
  final Address? address; // For editing existing address
  final Function(Address)? onSaved;

  AddAddressArguments({
    this.address,
    this.onSaved,
  });
}

class AddAddressScreen extends StatefulWidget {
  final AddAddressArguments? arguments;

  const AddAddressScreen({super.key, this.arguments});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _scrollController = ScrollController();
  late final AddressFormManager _formManager;

  bool _isLoading = false;

  bool get _isEditing => widget.arguments?.address != null;

  AddressManagementModel get addressManagementModel =>
      context.read<AddressManagementModel>();

  @override
  void initState() {
    super.initState();

    // Initialize form manager
    _formManager = AddressFormManager();

    // Initialize with existing address data if editing
    final address = widget.arguments?.address;
    if (address != null) {
      _formManager.initializeWithAddress(address);
    }

    // Load countries for country picker
    _loadCountries();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _formManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoHideKeyboard(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing
              ? S.of(context).editAddress
              : S.of(context).addNewAddress),
          elevation: 0,
        ),
        body: Column(
          children: [
            Expanded(
              child: LoadingBody(
                isLoading: _isLoading,
                child: Form(
                  key: _formManager.formKey,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Text(
                          _isEditing
                              ? S.of(context).updateYourAddressInformation
                              : S.of(context).enterYourAddressInformation,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),

                        // Dynamic fields using new widget
                        DynamicAddressFields(
                          configs: _formManager.configs,
                          controllers: _formManager.controllers,
                          initialPhoneNumber: _formManager.initialPhoneNumber,
                          onPhoneNumberChanged:
                              _formManager.onPhoneNumberChanged,
                          customFieldBuilder: (config, controller) {
                            // Custom builder for country field
                            if (config.type == AddressFieldType.country) {
                              return CountryPickerFormField(
                                config: config,
                                controller: controller,
                                countries: _formManager.countries,
                                onCountryChanged: () {
                                  if (mounted) setState(() {});
                                },
                                validator: config.required
                                    ? (value) {
                                        if (value?.isEmpty ?? true) {
                                          final title =
                                              config.type.getTitle(context) ??
                                                  config.type.name;
                                          return '$title ${S.of(context).isRequired}';
                                        }
                                        return null;
                                      }
                                    : null,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Save button using new widget
            AddressSaveButton(
              isLoading: _isLoading,
              isEditing: _isEditing,
              onPressed: _saveAddress,
            ),
          ],
        ),
      ),
    );
  }

  void _saveAddress() async {
    if (!_formManager.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final address = _formManager.buildAddress(
        id: widget.arguments?.address?.id,
      );

      // Call appropriate method based on editing mode
      if (_isEditing) {
        // Find the index of the address being edited
        final addressNotifier = addressManagementModel;
        final originalAddress = widget.arguments!.address!;

        final addressIndex = addressNotifier.addresses.indexWhere(
          (addr) => addr.compareFullInfo(originalAddress),
        );

        if (addressIndex != -1) {
          await addressNotifier.updateAddress(addressIndex, address);
        } else {
          // If not found in regular addresses, check if it's the default address
          if (addressNotifier.defaultAddress
                  ?.compareFullInfo(originalAddress) ==
              true) {
            // For default address, we need to add it to the list first, then update
            await addressNotifier.addAddress(address);
          } else {
            throw Exception(S.of(context).originalAddressNotFound);
          }
        }
      } else {
        await addressManagementModel.addAddress(address);
      }

      // If we reach here, the address was added successfully
      if (mounted) {
        widget.arguments?.onSaved?.call(address);

        await FlashHelper.message(context,
            message: _isEditing
                ? S.of(context).addressUpdatedSuccessfully
                : S.of(context).addressAddedSuccessfully);

        Navigator.of(context).pop(address);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCountries() async {
    try {
      final loadedCountries = await Services().widget.loadCountries() ?? [];
      _formManager.setCountries(loadedCountries);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Handle error silently, fallback to country picker dialog
    }
  }

  void _showErrorDialog(String errorMessage) {
    // Clean up the error message
    var cleanMessage = errorMessage;
    if (cleanMessage.startsWith('Exception: ')) {
      cleanMessage = cleanMessage.substring(11);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(S.of(context).validationError),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).pleaseCheckFollowingIssues,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                cleanMessage,
                style: TextStyle(
                  color: Colors.red.shade700,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).tips,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).validationTips,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(S.of(context).ok),
          ),
        ],
      ),
    );
  }
}
