import 'dart:async';

import 'package:flutter/material.dart';

import '../models/cart/cart_model.dart';
import '../services/index.dart';
import 'entities/fee.dart';

class FeeModel extends ChangeNotifier {
  final Services _service = Services();
  List<Fee>? fees = [];

  Future<void> getFees(
    CartModel cartModel,
    String? token,
    onSuccess, {
    Function? onError,
  }) async {
    try {
      var res = await _service.api.getFees(cartModel, token);
      if (res != null) {
        fees = res;
      }
      onSuccess(fees);
    } catch (err) {
      if (onError != null) {
        onError(err);
      }
      notifyListeners();
    }
  }
}
