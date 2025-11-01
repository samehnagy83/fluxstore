import 'package:country_pickers/country_pickers.dart' as picker;
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../../../common/config.dart';
import '../../../common/config/models/address_field_config.dart';
import '../../../models/entities/address.dart';
import '../../../models/index.dart' show Country;

/// Manager class to handle address form logic
/// Separates business logic from UI components
class AddressFormManager {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Map<int, AddressFieldType> _fieldPosition = {};
  final Map<int, AddressFieldConfig> _configs = {};
  final Map<AddressFieldType, TextEditingController> _textControllers = {};

  List<Country> countries = [];
  bool _disposed = false;

  // Phone number handling
  PhoneNumber? _initialPhoneNumber;
  PhoneNumber? _currentPhoneNumber;

  // Getters
  PhoneNumber? get initialPhoneNumber => _initialPhoneNumber;

  PhoneNumber? get currentPhoneNumber => _currentPhoneNumber;

  AddressFormManager() {
    _initializeControllers();
    _initializeFieldConfigs();
  }

  void _initializeControllers() {
    for (final fieldType in AddressFieldType.values) {
      _textControllers[fieldType] = TextEditingController();
    }
  }

  void _initializeFieldConfigs() {
    for (var config in Configurations.addressFields) {
      if (config.visible) {
        final index = _fieldPosition.values.length;
        _configs[index] = config;
        _fieldPosition[index] = config.type;
      }
    }
  }

  /// Initialize form with existing address data (for editing)
  void initializeWithAddress(Address address) {
    _textControllers[AddressFieldType.firstName]?.text =
        address.firstName ?? '';
    _textControllers[AddressFieldType.lastName]?.text = address.lastName ?? '';
    _textControllers[AddressFieldType.phoneNumber]?.text =
        address.phoneNumber ?? '';
    _textControllers[AddressFieldType.street]?.text = address.street ?? '';
    _textControllers[AddressFieldType.apartment]?.text =
        address.apartment ?? '';
    _textControllers[AddressFieldType.block]?.text = address.block ?? '';
    _textControllers[AddressFieldType.city]?.text = address.city ?? '';
    _textControllers[AddressFieldType.state]?.text = address.state ?? '';
    _textControllers[AddressFieldType.zipCode]?.text = address.zipCode ?? '';
    _textControllers[AddressFieldType.company]?.text = address.company ?? '';

    // Handle country field - ensure it's a valid country code
    final countryValue = address.country ?? '';
    if (countryValue.isNotEmpty) {
      final normalizedCountryCode = _normalizeCountryValue(countryValue);
      _textControllers[AddressFieldType.country]?.text = normalizedCountryCode;
    }

    // Initialize phone number for international validation
    _initializePhoneNumber(address.phoneNumber);
  }

  /// Initialize phone number for international validation
  void _initializePhoneNumber(String? phoneNumber) async {
    if (kPhoneNumberConfig.enablePhoneNumberValidation) {
      try {
        if (phoneNumber?.isNotEmpty ?? false) {
          _initialPhoneNumber = await PhoneNumber.getParsablePhoneNumber(
            PhoneNumber(
              dialCode: kPhoneNumberConfig.dialCodeDefault,
              isoCode: kPhoneNumberConfig.countryCodeDefault,
              phoneNumber: phoneNumber,
            ),
          );
        }
        // Default PhoneNumber object for initialization
        _initialPhoneNumber ??= PhoneNumber(
          dialCode: kPhoneNumberConfig.dialCodeDefault,
          isoCode: kPhoneNumberConfig.countryCodeDefault,
        );
        _currentPhoneNumber = _initialPhoneNumber;
      } catch (e) {
        // Fallback to default
        _initialPhoneNumber = PhoneNumber(
          dialCode: kPhoneNumberConfig.dialCodeDefault,
          isoCode: kPhoneNumberConfig.countryCodeDefault,
        );
        _currentPhoneNumber = _initialPhoneNumber;
      }
    }
  }

  /// Handle phone number changes from InternationalPhoneNumberInput
  void onPhoneNumberChanged(PhoneNumber phoneNumber) {
    _currentPhoneNumber = phoneNumber;
  }

  /// Normalize country value to valid ISO code
  String _normalizeCountryValue(String countryValue) {
    String? normalizedCountryCode;

    // Check if it's already a 2-letter country code
    if (countryValue.length == 2) {
      try {
        // Verify it's a valid country code
        picker.CountryPickerUtils.getCountryByIsoCode(
            countryValue.toUpperCase());
        normalizedCountryCode = countryValue.toUpperCase();
      } catch (e) {
        // Invalid country code, try to find by name
        normalizedCountryCode = _findCountryCodeByName(countryValue);
      }
    } else {
      // Assume it's a country name, try to find the code
      normalizedCountryCode = _findCountryCodeByName(countryValue);
    }

    return normalizedCountryCode ?? countryValue;
  }

  /// Find country code by country name using country_pickers package
  String? _findCountryCodeByName(String countryName) {
    try {
      // Get all country codes and try to find matching name
      final countryCodes = [
        'AD',
        'AE',
        'AF',
        'AG',
        'AI',
        'AL',
        'AM',
        'AO',
        'AQ',
        'AR',
        'AS',
        'AT',
        'AU',
        'AW',
        'AX',
        'AZ',
        'BA',
        'BB',
        'BD',
        'BE',
        'BF',
        'BG',
        'BH',
        'BI',
        'BJ',
        'BL',
        'BM',
        'BN',
        'BO',
        'BQ',
        'BR',
        'BS',
        'BT',
        'BV',
        'BW',
        'BY',
        'BZ',
        'CA',
        'CC',
        'CD',
        'CF',
        'CG',
        'CH',
        'CI',
        'CK',
        'CL',
        'CM',
        'CN',
        'CO',
        'CR',
        'CU',
        'CV',
        'CW',
        'CX',
        'CY',
        'CZ',
        'DE',
        'DJ',
        'DK',
        'DM',
        'DO',
        'DZ',
        'EC',
        'EE',
        'EG',
        'EH',
        'ER',
        'ES',
        'ET',
        'FI',
        'FJ',
        'FK',
        'FM',
        'FO',
        'FR',
        'GA',
        'GB',
        'GD',
        'GE',
        'GF',
        'GG',
        'GH',
        'GI',
        'GL',
        'GM',
        'GN',
        'GP',
        'GQ',
        'GR',
        'GS',
        'GT',
        'GU',
        'GW',
        'GY',
        'HK',
        'HM',
        'HN',
        'HR',
        'HT',
        'HU',
        'ID',
        'IE',
        'IL',
        'IM',
        'IN',
        'IO',
        'IQ',
        'IR',
        'IS',
        'IT',
        'JE',
        'JM',
        'JO',
        'JP',
        'KE',
        'KG',
        'KH',
        'KI',
        'KM',
        'KN',
        'KP',
        'KR',
        'KW',
        'KY',
        'KZ',
        'LA',
        'LB',
        'LC',
        'LI',
        'LK',
        'LR',
        'LS',
        'LT',
        'LU',
        'LV',
        'LY',
        'MA',
        'MC',
        'MD',
        'ME',
        'MF',
        'MG',
        'MH',
        'MK',
        'ML',
        'MM',
        'MN',
        'MO',
        'MP',
        'MQ',
        'MR',
        'MS',
        'MT',
        'MU',
        'MV',
        'MW',
        'MX',
        'MY',
        'MZ',
        'NA',
        'NC',
        'NE',
        'NF',
        'NG',
        'NI',
        'NL',
        'NO',
        'NP',
        'NR',
        'NU',
        'NZ',
        'OM',
        'PA',
        'PE',
        'PF',
        'PG',
        'PH',
        'PK',
        'PL',
        'PM',
        'PN',
        'PR',
        'PS',
        'PT',
        'PW',
        'PY',
        'QA',
        'RE',
        'RO',
        'RS',
        'RU',
        'RW',
        'SA',
        'SB',
        'SC',
        'SD',
        'SE',
        'SG',
        'SH',
        'SI',
        'SJ',
        'SK',
        'SL',
        'SM',
        'SN',
        'SO',
        'SR',
        'SS',
        'ST',
        'SV',
        'SX',
        'SY',
        'SZ',
        'TC',
        'TD',
        'TF',
        'TG',
        'TH',
        'TJ',
        'TK',
        'TL',
        'TM',
        'TN',
        'TO',
        'TR',
        'TT',
        'TV',
        'TW',
        'TZ',
        'UA',
        'UG',
        'UM',
        'US',
        'UY',
        'UZ',
        'VA',
        'VC',
        'VE',
        'VG',
        'VI',
        'VN',
        'VU',
        'WF',
        'WS',
        'YE',
        'YT',
        'ZA',
        'ZM',
        'ZW'
      ];

      final searchName = countryName.toLowerCase().trim();

      for (final countryCode in countryCodes) {
        try {
          final pickerCountry =
              picker.CountryPickerUtils.getCountryByIsoCode(countryCode);
          if (pickerCountry.name.toLowerCase() == searchName) {
            return countryCode;
          }
        } catch (e) {
          continue;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validate the form
  bool validate() {
    return formKey.currentState?.validate() ?? false;
  }

  /// Build Address object from form data
  Address buildAddress({String? id}) {
    return Address(
      id: id,
      firstName: _textControllers[AddressFieldType.firstName]?.text.trim(),
      lastName: _textControllers[AddressFieldType.lastName]?.text.trim(),
      phoneNumber: _getPhoneNumberForSave(),
      street: _textControllers[AddressFieldType.street]?.text.trim(),
      apartment: _textControllers[AddressFieldType.apartment]?.text.trim(),
      block: _textControllers[AddressFieldType.block]?.text.trim(),
      city: _textControllers[AddressFieldType.city]?.text.trim(),
      state: _textControllers[AddressFieldType.state]?.text.trim(),
      zipCode: _textControllers[AddressFieldType.zipCode]?.text.trim(),
      country: _textControllers[AddressFieldType.country]?.text.trim(),
      company: _textControllers[AddressFieldType.company]?.text.trim(),
    );
  }

  /// Get phone number for saving - uses international format if validation enabled
  String _getPhoneNumberForSave() {
    if (kPhoneNumberConfig.enablePhoneNumberValidation &&
        _currentPhoneNumber != null) {
      return _currentPhoneNumber!.phoneNumber ?? '';
    }
    return _textControllers[AddressFieldType.phoneNumber]?.text.trim() ?? '';
  }

  /// Get controller for specific field type
  TextEditingController? getController(AddressFieldType fieldType) {
    return _textControllers[fieldType];
  }

  /// Get field configurations
  Map<int, AddressFieldConfig> get configs => _configs;

  /// Get text controllers
  Map<AddressFieldType, TextEditingController> get controllers =>
      _textControllers;

  /// Set countries list
  void setCountries(List<Country> newCountries) {
    countries = newCountries;
  }

  /// Dispose all controllers
  void dispose() {
    if (_disposed) return;

    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    _disposed = true;
  }
}
