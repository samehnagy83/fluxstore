import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';

import '../../common/config.dart';
import '../../models/app_model.dart';

/// Shared phone number field widget that can be used across the app
/// Supports both regular TextFormField and InternationalPhoneNumberInput
/// based on kPhoneNumberConfig.enablePhoneNumberValidation setting
class PhoneNumberFieldWidget extends StatelessWidget {
  final TextEditingController phoneController;
  final PhoneNumber? initialPhoneNumber;
  final Function(PhoneNumber)? onPhoneNumberChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final String? labelText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const PhoneNumberFieldWidget({
    super.key,
    required this.phoneController,
    this.initialPhoneNumber,
    this.onPhoneNumberChanged,
    this.validator,
    this.enabled = true,
    this.labelText,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appModel = context.read<AppModel>();
    final langCode = appModel.langCode;
    final label = labelText ?? S.of(context).phoneNumber;

    // If phone number validation is not enabled, use regular text field
    if (!kPhoneNumberConfig.enablePhoneNumberValidation) {
      return _buildRegularTextField(context, label);
    }

    // Use InternationalPhoneNumberInput when validation is enabled
    return _buildInternationalPhoneField(
        context, theme, colorScheme, langCode, label);
  }

  Widget _buildRegularTextField(BuildContext context, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: phoneController,
      keyboardType: keyboardType ?? TextInputType.phone,
      textInputAction: textInputAction ?? TextInputAction.done,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.phone_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
    );
  }

  Widget _buildInternationalPhoneField(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String langCode,
    String label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        InternationalPhoneNumberInput(
          textFieldController: phoneController,
          inputDecoration: InputDecoration(
            // Issue flag will be render unexpected https://cln.sh/n5Vnbm62
            // labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainer,
          ),
          keyboardType: keyboardType ?? TextInputType.phone,
          keyboardAction: textInputAction ?? TextInputAction.done,
          onInputChanged: onPhoneNumberChanged ?? (_) {},
          // onInputValidated: (bool value) {},
          spaceBetweenSelectorAndTextField: 8,
          selectorConfig: SelectorConfig(
            enable: kPhoneNumberConfig.useInternationalFormat,
            showFlags: kPhoneNumberConfig.showCountryFlag,
            selectorType: kPhoneNumberConfig.selectorType,
            setSelectorButtonAsPrefixIcon:
                kPhoneNumberConfig.selectorFlagAsPrefixIcon,
            leadingPadding: 16,
            trailingSpace: false,
          ),
          selectorTextStyle: theme.textTheme.titleMedium,
          ignoreBlank: false,
          initialValue: initialPhoneNumber ??
              PhoneNumber(
                dialCode: kPhoneNumberConfig.dialCodeDefault,
                isoCode: kPhoneNumberConfig.countryCodeDefault,
              ),
          formatInput: kPhoneNumberConfig.formatInput,
          countries: kPhoneNumberConfig.customCountryList,
          locale: langCode,
          searchBoxDecoration: InputDecoration(
            labelText: S.of(context).searchByCountryNameOrDialCode,
          ),
          errorMessage: S.of(context).invalidPhoneNumber,
        ),
      ],
    );
  }
}
