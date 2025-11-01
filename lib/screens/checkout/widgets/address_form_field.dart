import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../../common/config/models/address_field_config.dart';
import '../../../widgets/common/phone_number_field_widget.dart';

/// Reusable address form field widget
/// Replaces helper method _buildTextField
class AddressFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;

  const AddressFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainer,
      ),
    );
  }
}

/// Widget for configurable address field
/// Replaces helper method _buildConfigurableField
class ConfigurableAddressField extends StatelessWidget {
  final AddressFieldConfig config;
  final TextEditingController controller;
  final Widget? customWidget; // For special fields like country picker

  const ConfigurableAddressField({
    super.key,
    required this.config,
    required this.controller,
    this.customWidget,
  });

  @override
  Widget build(BuildContext context) {
    final fieldType = config.type;
    final title = fieldType.getTitle(context) ?? fieldType.name;

    // Use custom widget if provided (e.g., country picker)
    if (customWidget != null) {
      return customWidget!;
    }

    return AddressFormField(
      controller: controller,
      label: title,
      icon: _getIconForFieldType(fieldType),
      keyboardType: fieldType.keyboardType,
      validator: config.required
          ? (value) {
              if (value?.isEmpty ?? true) {
                return '$title ${S.of(context).isRequired}';
              }
              return null;
            }
          : null,
      enabled: config.editable,
    );
  }

  IconData _getIconForFieldType(AddressFieldType fieldType) {
    switch (fieldType) {
      case AddressFieldType.firstName:
      case AddressFieldType.lastName:
        return Icons.person_outline;
      case AddressFieldType.phoneNumber:
        return Icons.phone_outlined;
      case AddressFieldType.street:
        return Icons.location_on_outlined;
      case AddressFieldType.apartment:
        return Icons.apartment_outlined;
      case AddressFieldType.block:
        return Icons.business_outlined;
      case AddressFieldType.city:
        return Icons.location_city_outlined;
      case AddressFieldType.state:
        return Icons.map_outlined;
      case AddressFieldType.country:
        return Icons.public_outlined;
      case AddressFieldType.zipCode:
        return Icons.local_post_office_outlined;
      case AddressFieldType.company:
        return Icons.business_center_outlined;
      default:
        return Icons.text_fields_outlined;
    }
  }
}

/// Dynamic form fields builder widget
/// Replaces helper method _buildDynamicFields
class DynamicAddressFields extends StatelessWidget {
  final Map<int, AddressFieldConfig> configs;
  final Map<AddressFieldType, TextEditingController> controllers;
  final Widget Function(AddressFieldConfig, TextEditingController)?
      customFieldBuilder;
  final PhoneNumber? initialPhoneNumber;
  final Function(PhoneNumber)? onPhoneNumberChanged;

  const DynamicAddressFields({
    super.key,
    required this.configs,
    required this.controllers,
    this.customFieldBuilder,
    this.initialPhoneNumber,
    this.onPhoneNumberChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Sort configs by position
    final sortedConfigs = configs.entries.toList()
      ..sort((a, b) => a.value.position.compareTo(b.value.position));

    final widgets = <Widget>[];

    for (var entry in sortedConfigs) {
      final config = entry.value;
      final fieldType = config.type;

      // Skip non-visible fields
      if (!config.visible) continue;

      // Skip special fields that need custom handling
      if ([AddressFieldType.searchAddress, AddressFieldType.selectAddress]
          .contains(fieldType)) {
        continue;
      }

      // Skip email field - we don't want to show it in address form
      if (fieldType == AddressFieldType.email) {
        continue;
      }

      final controller = controllers[fieldType];
      if (controller == null) continue;

      // Add spacing before field
      widgets.add(const SizedBox(height: 16));

      // Build the field widget
      if (customFieldBuilder != null && fieldType == AddressFieldType.country) {
        // Use custom builder for special fields like country
        widgets.add(customFieldBuilder!(config, controller));
      } else if (fieldType == AddressFieldType.phoneNumber) {
        // Use PhoneNumberFieldWidget for phone number field
        widgets.add(
          PhoneNumberFieldWidget(
            phoneController: controller,
            initialPhoneNumber: initialPhoneNumber,
            onPhoneNumberChanged: onPhoneNumberChanged,
            validator: config.required
                ? (value) {
                    if (value?.isEmpty ?? true) {
                      final title =
                          fieldType.getTitle(context) ?? fieldType.name;
                      return '$title ${S.of(context).isRequired}';
                    }
                    return null;
                  }
                : null,
            enabled: config.editable,
          ),
        );
      } else {
        widgets.add(
          ConfigurableAddressField(
            config: config,
            controller: controller,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
