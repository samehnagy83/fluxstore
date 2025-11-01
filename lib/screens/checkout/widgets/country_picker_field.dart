import 'package:collection/collection.dart' show IterableExtension;
import 'package:country_pickers/country_pickers.dart' as picker;
import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';

import '../../../common/config/models/address_field_config.dart';
import '../../../models/index.dart' show Country;

/// Country picker field widget with form validation
/// Replaces helper method _buildCountryField
class CountryPickerField extends StatefulWidget {
  final AddressFieldConfig config;
  final TextEditingController controller;
  final List<Country> countries;
  final VoidCallback? onCountryChanged;
  final String? Function(String?)? validator;

  const CountryPickerField({
    super.key,
    required this.config,
    required this.controller,
    required this.countries,
    this.onCountryChanged,
    this.validator,
  });

  @override
  State<CountryPickerField> createState() => _CountryPickerFieldState();
}

class _CountryPickerFieldState extends State<CountryPickerField> {
  @override
  Widget build(BuildContext context) {
    return _CountryPickerFieldWithValidation(
      config: widget.config,
      controller: widget.controller,
      countries: widget.countries,
      hasError: false, // This is only used for standalone usage, not in form
      onCountryChanged: widget.onCountryChanged,
    );
  }
}

/// Form field wrapper for country picker to integrate with Flutter's Form validation
class CountryPickerFormField extends FormField<String> {
  final AddressFieldConfig config;
  final TextEditingController controller;
  final List<Country> countries;
  final VoidCallback? onCountryChanged;

  CountryPickerFormField({
    super.key,
    required this.config,
    required this.controller,
    required this.countries,
    this.onCountryChanged,
    super.validator,
    super.enabled = true,
  }) : super(
          initialValue: controller.text,
          builder: (FormFieldState<String> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CountryPickerFieldWithValidation(
                  config: config,
                  controller: controller,
                  countries: countries,
                  hasError: state.hasError,
                  onCountryChanged: () {
                    state.didChange(controller.text);
                    onCountryChanged?.call();
                  },
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        color: Theme.of(state.context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}

/// Internal widget for country picker with validation state
class _CountryPickerFieldWithValidation extends StatelessWidget {
  final AddressFieldConfig config;
  final TextEditingController controller;
  final List<Country> countries;
  final VoidCallback? onCountryChanged;
  final bool hasError;

  const _CountryPickerFieldWithValidation({
    required this.config,
    required this.controller,
    required this.countries,
    required this.hasError,
    this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    var countryName = S.of(context).country;
    final currentCountry = controller.text;

    if (currentCountry.isNotEmpty) {
      try {
        if (countries.isEmpty) {
          // Use country_pickers to get country name from code
          countryName =
              picker.CountryPickerUtils.getCountryByIsoCode(currentCountry)
                  .name;
        } else {
          // Use loaded countries list to find country name
          countryName = countries
                  .firstWhereOrNull((element) => element.code == currentCountry)
                  ?.name ??
              countryName;
        }
      } catch (e) {
        // If country code is invalid, try to use it as display name
        // This handles cases where the stored value might be a country name instead of code
        if (currentCountry.length > 2) {
          countryName = currentCountry;
        } else {
          countryName = S.of(context).country;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (countries.length == 1)
          _SingleCountryDisplay(
            countryName: countryName,
            hasError: hasError,
          )
        else
          _CountrySelector(
            config: config,
            countryName: countryName,
            hasError: hasError,
            onTap: config.editable
                ? () => _openCountryPickerBottomSheet(context)
                : null,
          ),
      ],
    );
  }

  void _openCountryPickerBottomSheet(BuildContext context) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (contextBuilder) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(contextBuilder).viewInsets.bottom,
          ),
          child: GestureDetector(
            onTap: Navigator.of(context).pop,
            behavior: HitTestBehavior.translucent,
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              // Start at 60% of screen
              minChildSize: 0.3,
              // Minimum 30% of screen
              maxChildSize: 0.9,
              // Maximum 90% of screen
              snap: true,
              // Snap to positions
              snapSizes: const [0.3, 0.6, 0.9],
              // Snap points
              builder: (context, scrollController) => CountryPickerBottomSheet(
                countries: countries,
                scrollController: scrollController,
                onCountrySelected: (Country? country) {
                  if (country != null) {
                    controller.text = country.code ?? '';
                    onCountryChanged?.call();
                  }
                  Navigator.pop(contextBuilder);
                },
              ),
            ),
          ),
        ),
      );
}

/// Single country display widget (when only one country available)
class _SingleCountryDisplay extends StatelessWidget {
  final String countryName;
  final bool hasError;

  const _SingleCountryDisplay({
    required this.countryName,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: hasError ? colorScheme.error : colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surfaceContainerLowest,
      ),
      child: Row(
        children: [
          Icon(
            Icons.public_outlined,
            color: hasError ? colorScheme.error : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Text(
            countryName,
            style: TextStyle(
              fontSize: 16,
              color: hasError ? colorScheme.error : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Country selector widget (clickable)
class _CountrySelector extends StatelessWidget {
  final AddressFieldConfig config;
  final String countryName;
  final VoidCallback? onTap;
  final bool hasError;

  const _CountrySelector({
    required this.config,
    required this.countryName,
    this.onTap,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasError ? colorScheme.error : colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(12),
          color: config.editable
              ? colorScheme.surfaceContainer
              : colorScheme.surfaceContainerLow,
        ),
        child: Row(
          children: [
            Icon(
              Icons.public_outlined,
              color:
                  hasError ? colorScheme.error : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                countryName,
                style: TextStyle(
                  fontSize: 16,
                  color: hasError
                      ? colorScheme.error
                      : (config.editable
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant),
                ),
              ),
            ),
            if (config.editable)
              Icon(
                Icons.arrow_drop_down,
                color:
                    hasError ? colorScheme.error : colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

/// Country picker bottom sheet widget
class CountryPickerBottomSheet extends StatefulWidget {
  const CountryPickerBottomSheet({
    super.key,
    required this.countries,
    required this.scrollController,
    required this.onCountrySelected,
  });

  final List<Country> countries;
  final ScrollController scrollController;
  final void Function(Country?) onCountrySelected;

  @override
  State<CountryPickerBottomSheet> createState() =>
      _CountryPickerBottomSheetState();
}

class _CountryPickerBottomSheetState extends State<CountryPickerBottomSheet> {
  late final List<Country> _listCountry;
  late final List<Country> _listCountryShow;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // If countries list is empty, use all countries from country_pickers package
    if (widget.countries.isEmpty) {
      _listCountry = _getAllCountriesFromPicker();
    } else {
      _listCountry = List<Country>.from(widget.countries);
    }
    _listCountryShow = List<Country>.from(_listCountry);
  }

  /// Get all countries from country_pickers package
  List<Country> _getAllCountriesFromPicker() {
    final allCountries = <Country>[];

    // Get all country codes from country_pickers package
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

    for (final countryCode in countryCodes) {
      try {
        final pickerCountry =
            picker.CountryPickerUtils.getCountryByIsoCode(countryCode);
        final country = Country(
          id: pickerCountry.isoCode,
          name: pickerCountry.name,
        );
        country.code = pickerCountry.isoCode;
        allCountries.add(country);
      } catch (e) {
        // Skip invalid country codes
        continue;
      }
    }

    // Sort countries by name
    allCountries.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));

    return allCountries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 5,
            width: 50,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).country,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_listCountryShow.length} ${S.of(context).countries}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: S.of(context).searchCountries,
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(
                  Icons.search,
                  color: colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainer,
              ),
              style: TextStyle(color: colorScheme.onSurface),
              onChanged: (value) {
                setState(() {
                  _listCountryShow.clear();
                  if (value.isEmpty) {
                    _listCountryShow.addAll(_listCountry);
                  } else {
                    _listCountryShow.addAll(
                      _listCountry.where((country) =>
                          country.name
                              ?.toLowerCase()
                              .contains(value.toLowerCase()) ??
                          false),
                    );
                  }
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Countries list
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: _listCountryShow.length,
              itemBuilder: (context, index) {
                final country = _listCountryShow[index];
                return InkWell(
                  onTap: () => widget.onCountrySelected(country),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Flag
                        Container(
                          width: 40,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: colorScheme.outline),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: country.icon != null
                                ? FluxImage(
                                    imageUrl: country.icon!,
                                    fit: BoxFit.cover,
                                  )
                                : (country.code != null
                                    ? Image.asset(
                                        picker.CountryPickerUtils
                                            .getFlagImageAssetPath(
                                                country.code!),
                                        fit: BoxFit.cover,
                                        package: 'country_pickers',
                                        errorBuilder: (_, __, ___) => Container(
                                          color:
                                              colorScheme.surfaceContainerLow,
                                          child: Icon(
                                            Icons.flag,
                                            size: 16,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: colorScheme.surfaceContainerLow,
                                        child: Icon(
                                          Icons.flag,
                                          size: 16,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      )),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Country name
                        Expanded(
                          child: Text(
                            country.name ?? S.of(context).unknown,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
