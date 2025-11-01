import 'dart:async';

import 'package:flutter/material.dart';

import '../common/constants.dart';
import '../data/boxes.dart';
import '../services/index.dart';
import 'entities/address.dart';

class AddressManagementModel with ChangeNotifier {
  AddressManagementModel();

  final Services _service = Services();

  List<Address> _addresses = [];
  Address? _defaultAddress;
  bool _isLoading = false;
  String? _errorMessage;

  List<Address> get addresses => _addresses;

  Address? get defaultAddress => _defaultAddress;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Fetch customer addresses from Shopify API
  Future<void> fetchCustomerAddresses() async {
    final user = UserBox().userInfo;
    if (user?.id == null) {
      _setError('User not logged in');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Get customer info including addresses from Shopify API
      final customerInfo =
          await _service.api.getUserInfo(UserBox().userInfo?.cookie);

      if (customerInfo != null) {
        // Extract addresses from User entity
        _addresses = customerInfo.addresses;

        // Set default address from shipping/billing if available
        if (customerInfo.shipping case final shipping?) {
          _defaultAddress = Address(
            id: shipping.id,
            firstName: shipping.firstName,
            lastName: shipping.lastName,
            street: shipping.address1,
            apartment: shipping.address2,
            company: shipping.company,
            city: shipping.city,
            state: shipping.state,
            country: shipping.country,
            zipCode: shipping.postCode,
            phoneNumber: shipping.phone,
          );
        }

        // Update local storage
        UserBox().addresses = _addresses;

        printLog('Fetched ${_addresses.length} addresses from Shopify');
      }
    } catch (e) {
      printLog('Error fetching customer addresses: $e');
      _setError('Failed to load addresses: ${e.toString()}');

      // Fallback to local addresses
      _addresses = UserBox().addresses;
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new address
  Future<bool> addAddress(Address address) async {
    final user = UserBox().userInfo;
    if (user?.id == null) {
      _setError('User not logged in');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Try to create address via Shopify API
      final success = await _createAddressOnShopify(address);

      if (success) {
        // Add to local list and storage
        _addresses.add(address);
        UserBox().addresses = _addresses;
        printLog('Address added successfully');
        return true;
      } else {
        // Fallback to local storage only
        _addresses.add(address);
        UserBox().addresses = _addresses;
        printLog('Address added to local storage (Shopify API not available)');
        return true;
      }
    } catch (e) {
      printLog('Error adding address: $e');
      _setError('Failed to add address: ${e.toString()}');
      rethrow; // Rethrow để AddAddressScreen có thể catch và hiển thị error dialog
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing address
  Future<bool> updateAddress(int index, Address updatedAddress) async {
    if (index < 0 || index >= _addresses.length) {
      _setError('Invalid address index');
      return false;
    }

    final user = UserBox().userInfo;
    if (user?.id == null) {
      _setError('User not logged in');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Get the current address to get its ID
      final currentAddress = _addresses[index];
      final addressId = currentAddress.id;

      // Try to update address via Shopify API
      final success = await _updateAddressOnShopify(updatedAddress, addressId);

      if (success) {
        // Preserve the ID from the original address
        updatedAddress.id = addressId;
        _addresses[index] = updatedAddress;
        UserBox().addresses = _addresses;
        printLog('Address updated successfully');
        return true;
      } else {
        // Fallback to local storage only
        updatedAddress.id = addressId;
        _addresses[index] = updatedAddress;
        UserBox().addresses = _addresses;
        printLog(
            'Address updated in local storage (Shopify API not available)');
        return true;
      }
    } catch (e) {
      printLog('Error updating address: $e');
      _setError('Failed to update address: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an address
  Future<bool> deleteAddress(int index) async {
    if (index < 0 || index >= _addresses.length) {
      _setError('Invalid address index');
      return false;
    }

    final user = UserBox().userInfo;
    if (user?.id == null) {
      _setError('User not logged in');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Get the address ID
      final addressId = _addresses[index].id;

      // Try to delete address via Shopify API
      final success = await _deleteAddressOnShopify(addressId);

      if (success) {
        _addresses.removeAt(index);
        UserBox().addresses = _addresses;
        printLog('Address deleted successfully');
        return true;
      } else {
        // Fallback to local storage only
        _addresses.removeAt(index);
        UserBox().addresses = _addresses;
        printLog(
            'Address deleted from local storage (Shopify API not available)');
        return true;
      }
    } catch (e) {
      printLog('Error deleting address: $e');
      _setError('Failed to delete address: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set default address
  Future<bool> setDefaultAddress(int index) async {
    if (index < 0 || index >= _addresses.length) {
      _setError('Invalid address index');
      return false;
    }

    final user = UserBox().userInfo;
    if (user?.id == null) {
      _setError('User not logged in');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Get the address ID
      final addressId = _addresses[index].id;

      // Try to set default address via Shopify API
      final success = await _setDefaultAddressOnShopify(addressId);

      if (success) {
        _defaultAddress = _addresses[index];
        printLog('Default address set successfully');
        return true;
      } else {
        // Fallback to local storage only
        _defaultAddress = _addresses[index];
        printLog(
            'Default address set in local storage (Shopify API not available)');
        return true;
      }
    } catch (e) {
      printLog('Error setting default address: $e');
      _setError('Failed to set default address: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load addresses from local storage
  void loadLocalAddresses() {
    _addresses = UserBox().addresses;
    notifyListeners();
  }

  /// Clear all addresses
  void clearAddresses() {
    _addresses.clear();
    _defaultAddress = null;
    UserBox().addresses = [];
    notifyListeners();
  }

  /// Helper methods for Shopify API integration

  Future<bool> _createAddressOnShopify(Address address) async {
    try {
      final user = UserBox().userInfo;
      final customerAccessToken = user?.cookie;

      if (customerAccessToken == null) {
        printLog('No customer access token available');
        return false;
      }

      // Convert Address to Shopify MailingAddressInput format
      final addressInput = <String, dynamic>{
        'firstName': address.firstName?.trim(),
        'lastName': address.lastName?.trim(),
        'address1': address.street?.trim(),
        'address2': address.apartment?.trim(), // apartment goes to address2
        'company': address.company?.trim(),
        'city': address.city?.trim(),
        'province': address.state?.trim() ?? address.city?.trim(),
        'country': address.country?.trim(),
        'zip': address.zipCode?.trim(),
        'phone': address.phoneNumber?.trim(),
      };

      // Remove null or empty values to avoid sending unnecessary data
      addressInput.removeWhere(
          (key, value) => value == null || value.toString().trim().isEmpty);

      final result = await _service.api.createCustomerAddress(
        customerAccessToken: customerAccessToken,
        address: addressInput,
      );

      if (result != null) {
        // Update the address with the returned ID from Shopify
        address.id = result['id'];
        printLog(
            'Address created successfully on Shopify with ID: ${address.id}');
        return true;
      }

      return false;
    } catch (e) {
      printLog('Error creating address on Shopify: $e');
      rethrow;
    }
  }

  Future<bool> _updateAddressOnShopify(
      Address address, String? addressId) async {
    try {
      final user = UserBox().userInfo;
      final customerAccessToken = user?.cookie;

      if (customerAccessToken == null || addressId == null) {
        printLog('No customer access token or address ID available');
        return false;
      }

      var state = address.state;
      if (state == null || state.isEmpty) {
        state = address.city;
      }

      // Convert Address to Shopify MailingAddressInput format
      final addressInput = {
        'firstName': address.firstName,
        'lastName': address.lastName,
        'address1': address.street,
        'address2': address.apartment,
        'city': address.city,
        'province': state,
        'country': address.country,
        'zip': address.zipCode,
        'phone': address.phoneNumber,
        'company': address.company,
      };

      final result = await _service.api.updateCustomerAddress(
        customerAccessToken: customerAccessToken,
        addressId: addressId,
        address: addressInput,
      );

      if (result != null) {
        printLog('Address updated successfully on Shopify');
        return true;
      }

      return false;
    } catch (e) {
      printLog('Error updating address on Shopify: $e');
      return false;
    }
  }

  Future<bool> _deleteAddressOnShopify(String? addressId) async {
    try {
      final user = UserBox().userInfo;
      final customerAccessToken = user?.cookie;

      if (customerAccessToken == null || addressId == null) {
        printLog('No customer access token or address ID available');
        return false;
      }

      final result = await _service.api.deleteCustomerAddress(
        customerAccessToken: customerAccessToken,
        addressId: addressId,
      );

      if (result != null) {
        printLog('Address deleted successfully on Shopify');
        return true;
      }

      return false;
    } catch (e) {
      printLog('Error deleting address on Shopify: $e');
      return false;
    }
  }

  Future<bool> _setDefaultAddressOnShopify(String? addressId) async {
    try {
      final user = UserBox().userInfo;
      final customerAccessToken = user?.cookie;

      if (customerAccessToken == null || addressId == null) {
        printLog('No customer access token or address ID available');
        return false;
      }

      final result = await _service.api.updateCustomerDefaultAddress(
        customerAccessToken: customerAccessToken,
        addressId: addressId,
      );

      if (result != null) {
        printLog('Default address updated successfully on Shopify');
        return true;
      }

      return false;
    } catch (e) {
      printLog('Error setting default address on Shopify: $e');
      return false;
    }
  }
}
