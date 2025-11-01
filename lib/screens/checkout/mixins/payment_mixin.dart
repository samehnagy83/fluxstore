import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:inspireui/utils/logs.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../common/config.dart';
import '../../../common/tools.dart';
import '../../../models/booking/booking_model.dart';
import '../../../models/index.dart';
import '../../../modules/analytics/analytics.dart';
import '../../../modules/dynamic_layout/helper/helper.dart';
import '../../../modules/native_payment/flutterwave/services.dart';
import '../../../modules/native_payment/mercado_pago/index.dart';
import '../../../modules/native_payment/paystack/services.dart';
import '../../../modules/native_payment/paytm/services.dart';
import '../../../modules/native_payment/phonepe/services.dart';
import '../../../modules/native_payment/razorpay/index.dart';
import '../../../services/services.dart';

mixin PaymentMixin<T extends StatefulWidget> on State<T>, RazorDelegate {
  bool isPaying = false;
  String? selectedId;

  Function? get onBack;

  Function(Order)? get onFinish;
  Function(bool)? get onLoading;

  AppLifecycleListener? _listener;

  CartModel get _cartModel => context.read<CartModel>();
  FeeModel get _feeModel => context.read<FeeModel>();
  UserModel get _userModel => context.read<UserModel>();
  TaxModel get _taxModel => context.read<TaxModel>();
  AppModel get _appModel => context.read<AppModel>();
  PaymentMethodModel get _paymentMethodModel =>
      context.read<PaymentMethodModel>();

  @override
  void handlePaymentSuccess(PaymentSuccessResponse response, Order? order) {
    onLoading?.call(false);
    isPaying = false;
    if (order != null) {
      onFinish?.call(order);
    }
  }

  @override
  void handlePaymentFailure(PaymentFailureResponse response) {
    onLoading?.call(false);
    isPaying = false;
    final body = jsonDecode(response.message!);
    if (body['error'] != null &&
        body['error']['reason'] != 'payment_cancelled') {
      Tools.showSnackBar(
          ScaffoldMessenger.of(context), body['error']['description']);
    }
    printLog(response.message);
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      final langCode = _appModel.langCode;
      final token = _userModel.user?.cookie;

      _paymentMethodModel.getPaymentMethods(
        cartModel: _cartModel,
        shippingMethod: _cartModel.shippingMethod,
        token: token,
        langCode: langCode,
      );

      if (kPaymentConfig.enableReview == false) {
        _fetchAdditionalFees();
      }
    });
  }

  @override
  void dispose() {
    _listener?.dispose();
    super.dispose();
  }

  Future<void> _fetchAdditionalFees() async {
    final token = _userModel.user?.cookie;

    // Need to fetch fees first before taxes
    await _feeModel.getFees(
      _cartModel,
      token,
      (fees) {
        _cartModel.setFees(fees);
        setState(() {});
      },
    );
    await _taxModel.getTaxes(
      _cartModel,
      token,
      (taxesTotal, taxes, isIncludingTax) {
        _cartModel.setTaxInfo(taxes, taxesTotal, isIncludingTax);
        setState(() {});
      },
    );
  }

  void showSnackbar() {
    Tools.showSnackBar(
        ScaffoldMessenger.of(context), S.of(context).orderStatusProcessing);
  }

  Future<bool>? createBooking(BookingModel? bookingInfo) async {
    return Services().api.createBooking(bookingInfo)!;
  }

  Future<void> createOrderOnWebsite({
    paid = false,
    bacs = false,
    cod = false,
    AdditionalPaymentInfo? additionalPaymentInfo,
    required Function(Order?) onFinish,
    bool hideLoading = true,
  }) async {
    onLoading!(true);
    await Services().widget.createOrder(
      context,
      paid: paid,
      cod: cod,
      bacs: bacs,
      additionalPaymentInfo: additionalPaymentInfo,
      onLoading: onLoading,
      success: onFinish,
      error: (message) {
        Tools.showSnackBar(ScaffoldMessenger.of(context), message);
      },
    );
    if (hideLoading) {
      onLoading?.call(false);
    }
  }

  Future<void> _deletePendingOrder(String? orderId) async {
    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      await Services().api.deleteOrder(orderId, token: userModel.user?.cookie);
    } catch (_) {}
  }

  Future<void> createOrder(
      {paid = false,
      bacs = false,
      cod = false,
      AdditionalPaymentInfo? additionalPaymentInfo}) async {
    await createOrderOnWebsite(
        paid: paid,
        bacs: bacs,
        cod: cod,
        additionalPaymentInfo: additionalPaymentInfo,
        onFinish: (Order? order) async {
          if (order != null) {
            onFinish!(order);
          }
        });
  }

  void placeOrder(PaymentMethodModel paymentMethodModel, CartModel cartModel) {
    final currencyRate = _appModel.currencyRate;

    onLoading!(true);
    isPaying = true;
    if (paymentMethodModel.paymentMethods.isNotEmpty) {
      final paymentMethod = paymentMethodModel.paymentMethods
          .firstWhere((item) => item.id == cartModel.paymentMethod?.id);

      var isSubscriptionProduct = cartModel.item.values.firstWhere(
              (element) =>
                  element?.type == 'variable-subscription' ||
                  element?.type == 'subscription',
              orElse: () => null) !=
          null;
      _cartModel.setPaymentMethod(paymentMethod);

      Analytics.triggerAddPaymentInfo(paymentMethod.title, context);

      /// Use Native payment

      /// Direct bank transfer (BACS)

      if (!isSubscriptionProduct &&
          kBankTransferConfig
              .getValueList('paymentMethodIds')
              .contains(paymentMethod.id)) {
        onLoading?.call(false);
        isPaying = false;

        final bodyForm = Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      S.of(context).cancel,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              HtmlWidget(
                paymentMethod.description!,
                textStyle: Theme.of(context).textTheme.bodySmall,
              ),
              const Expanded(child: SizedBox(height: 10)),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onLoading!(true);
                  isPaying = true;
                  Services().widget.placeOrder(
                    context,
                    cartModel: cartModel,
                    onLoading: onLoading,
                    paymentMethod: paymentMethod,
                    success: (Order? order) async {
                      if (order != null) {
                        for (var item in order.lineItems) {
                          var product =
                              cartModel.getProductById(item.productId!);

                          if (product?.bookingInfo != null) {
                            product!.bookingInfo!.idOrder = order.id;
                            var booking =
                                await createBooking(product.bookingInfo)!;

                            Tools.showSnackBar(
                                ScaffoldMessenger.of(context),
                                booking
                                    ? 'Booking success!'
                                    : 'Booking error!');
                          }
                        }
                        onFinish!(order);
                      }
                      onLoading?.call(false);
                      isPaying = false;
                    },
                    error: (message) {
                      onLoading?.call(false);
                      if (message != null) {
                        Tools.showSnackBar(
                            ScaffoldMessenger.of(context), message);
                      }
                      isPaying = false;
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: Text(
                  S.of(context).ok,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
        if (Layout.isDisplayDesktop(context)) {
          showDialog(
            context: context,
            builder: (context) => Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                width: 500,
                height: 500,
                padding: const EdgeInsets.all(10.0),
                child: bodyForm,
              ),
            ),
          );
          return;
        }

        showModalBottomSheet(
          context: context,
          builder: (sContext) => bodyForm,
        );

        return;
      }

      /// MercadoPago payment
      final availableMercadoPago = kMercadoPagoConfig
              .getValueList('paymentMethodIds')
              .contains(paymentMethod.id) &&
          kMercadoPagoConfig['enabled'] == true;
      if (!isSubscriptionProduct && availableMercadoPago) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MercadoPagoPayment(
              onFinish: (number, paid) {
                if (number == null) {
                  onLoading?.call(false);
                  isPaying = false;
                  return;
                } else {
                  createOrder(paid: paid).then((value) {
                    onLoading?.call(false);
                    isPaying = false;
                  });
                }
              },
            ),
          ),
        );
        return;
      }

      /// RazorPay payment
      /// Check below link for parameters:
      /// https://razorpay.com/docs/payment-gateway/web-integration/standard/#step-2-pass-order-id-and-other-options
      final availableRazorpay = kRazorpayConfig
              .getValueList('paymentMethodIds')
              .contains(paymentMethod.id) &&
          kRazorpayConfig['enabled'] == true;

      if (!isSubscriptionProduct && availableRazorpay) {
        createOrderOnWebsite(
            paid: false,
            hideLoading: false,
            onFinish: (Order? order) async {
              if (order != null) {
                final amount = (order.total ?? 0).toString();
                final razorpayServices = RazorServices(
                  amount: amount,
                  currencyCode: cartModel.currencyCode!.toUpperCase(),
                  order: order,
                  userInfo: RazorUserInfo(
                    email: cartModel.address?.email,
                    phone: cartModel.address?.phoneNumber,
                    fullName:
                        '${cartModel.address?.firstName ?? ''} ${cartModel.address?.lastName ?? ''}'
                            .trim(),
                  ),
                  delegate: this,
                  onLoading: onLoading,
                );
                try {
                  await razorpayServices.openPayment();
                } catch (e) {
                  onLoading?.call(false);
                  Tools.showSnackBar(
                      ScaffoldMessenger.of(context), e.toString());
                  isPaying = false;
                  unawaited(_deletePendingOrder(order.id));
                }
              }
            });
        return;
      }

      /// PayTm payment.
      /// Check below link for parameters:
      /// https://developer.paytm.com/docs/all-in-one-sdk/hybrid-apps/flutter/
      final availablePayTm = kPayTmConfig
              .getValueList('paymentMethodIds')
              .contains(paymentMethod.id) &&
          kPayTmConfig['enabled'] == true;
      if (!isSubscriptionProduct && availablePayTm) {
        createOrderOnWebsite(
            paid: false,
            onFinish: (Order? order) async {
              if (order != null) {
                final paytmServices = PayTmServices(
                  amount: cartModel.getPaymentTotal()!.toString(),
                  orderId: order.id!,
                  email: cartModel.address?.email,
                );
                try {
                  await paytmServices.openPayment();
                  onFinish!(order);
                } catch (e) {
                  Tools.showSnackBar(
                      ScaffoldMessenger.of(context), e.toString());
                  isPaying = false;
                  unawaited(_deletePendingOrder(order.id));
                }
              }
            });
        return;
      }

      /// PayStack payment.
      final availablePayStack = kPayStackConfig
              .getValueList('paymentMethodIds')
              .contains(paymentMethod.id) &&
          kPayStackConfig['enabled'] == true;
      if (!isSubscriptionProduct && availablePayStack) {
        final isSupported =
            List.from(kPayStackConfig['supportedCurrencies'] ?? [])
                    .firstWhereOrNull((e) =>
                        e.toString().toLowerCase() ==
                        cartModel.currencyCode?.toLowerCase()) !=
                null;
        if (isSupported) {
          createOrderOnWebsite(
              paid: false,
              onFinish: (Order? order) async {
                if (order != null) {
                  final payStackServices = PayStackServices(
                    amount: order.total?.toString() ?? '',
                    orderId: order.id!,
                    email: cartModel.address?.email,
                  );
                  try {
                    await payStackServices.openPayment(context, onLoading!);
                    onFinish!(order);
                  } catch (e) {
                    Tools.showSnackBar(
                        ScaffoldMessenger.of(context), e.toString());
                    isPaying = false;
                    unawaited(_deletePendingOrder(order.id));
                  }
                }
              });
        } else {
          isPaying = false;
          onLoading?.call(false);
          Tools.showSnackBar(
              ScaffoldMessenger.of(context),
              S.of(context).currencyIsNotSupported(
                  cartModel.currencyCode?.toUpperCase() ?? ''));
        }
        return;
      }

      /// Flutterwave payment.
      final availableFlutterwave = kFlutterwaveConfig
              .getValueList('paymentMethodIds')
              .contains(paymentMethod.id) &&
          kFlutterwaveConfig['enabled'] == true;
      if (!isSubscriptionProduct && availableFlutterwave) {
        createOrderOnWebsite(
            paid: false,
            onFinish: (Order? order) async {
              if (order != null) {
                final flutterwaveServices = FlutterwaveServices(
                    amount: PriceTools.getPriceValueByCurrency(
                      cartModel.getPaymentTotal() ?? 0.0,
                      cartModel.currencyCode ?? '',
                      currencyRate,
                    ).toString(),
                    orderId: order.id!,
                    email: cartModel.address?.email,
                    name: cartModel.address?.fullName,
                    phone: cartModel.address?.phoneNumber,
                    currency: cartModel.currencyCode!,
                    paymentMethod: paymentMethod.title);
                try {
                  await flutterwaveServices.openPayment(context, onLoading!);
                  onFinish!(order);
                } catch (e) {
                  Tools.showSnackBar(
                      ScaffoldMessenger.of(context), e.toString());
                  isPaying = false;
                  unawaited(_deletePendingOrder(order.id));
                }
              }
            });
        return;
      }

      /// PhonePe payment.
      final availablePhonePe = kPhonePeConfig
              .getValueList<String>('paymentMethodIds')
              .anyTheSame(paymentMethod.id) &&
          (kPhonePeConfig['enabled'] ?? false);

      if (!isSubscriptionProduct && availablePhonePe) {
        createOrderOnWebsite(
            paid: false,
            hideLoading: false,
            onFinish: (Order? order) async {
              if (order != null) {
                PhonePeServices(
                    amount: order.total ?? 0,
                    orderId: order.id!,
                    user: cartModel.user,
                    onSuccess: () {
                      onLoading?.call(false);
                      isPaying = false;
                      onFinish!(order);
                    },
                    onFail: (e) {
                      if (e.isNotEmpty) {
                        Tools.showSnackBar(
                            ScaffoldMessenger.of(context), e.toString());
                      }
                      isPaying = false;
                      onLoading?.call(false);
                      unawaited(_deletePendingOrder(order.id));
                    },
                    onCancel: () {
                      isPaying = false;
                      onLoading?.call(false);
                      unawaited(_deletePendingOrder(order.id));
                    }).openPayment(context);
              }
            });
        return;
      }

      /// Use WebView Payment per frameworks
      Services().widget.placeOrder(
        context,
        cartModel: cartModel,
        onLoading: onLoading,
        paymentMethod: paymentMethod,
        success: (Order? order) async {
          var booking = false;
          if (order != null) {
            // for (var item in order.lineItems) {
            // var product = cartModel.getProductById(item.productId!);
            for (var key in cartModel.productsInCart.keys) {
              var productBooking =
                  cartModel.cartItemMetaDataInCart[key]?.bookingInfo;
              if (productBooking != null) {
                productBooking.idOrder = order.id;
                booking = await createBooking(productBooking)!;
                Tools.showSnackBar(ScaffoldMessenger.of(context),
                    booking ? 'Booking success!' : 'Booking error!');
              }
              // }
            }
            onFinish!(order);
          }
          onLoading?.call(false);
          isPaying = false;
        },
        error: (message) {
          onLoading?.call(false);
          if (message != null) {
            Tools.showSnackBar(ScaffoldMessenger.of(context), message);
          }

          isPaying = false;
        },
      );
    }
  }
}
