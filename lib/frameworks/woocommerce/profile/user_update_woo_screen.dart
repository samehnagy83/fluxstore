import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../common/extensions/extensions.dart';
import '../../../common/tools/flash.dart';
import '../../../models/entities/user.dart';
import '../../../models/user_model.dart';
import '../../../modules/dynamic_layout/helper/helper.dart';
import '../../../services/index.dart';
import '../../../widgets/common/xfile_image_widget.dart';
import 'user_update_model.dart';

class UserUpdateWooScreen extends StatefulWidget {
  @override
  State<UserUpdateWooScreen> createState() => _UserUpdateScreenState();
}

class _UserUpdateScreenState extends State<UserUpdateWooScreen> {
  final formKey = GlobalKey<FormState>();

  Widget renderBackgroundAvatar(dynamic value) {
    Widget? avatar;
    if (value is String && value.isNotEmpty) {
      avatar = FluxImage(
        imageUrl: value,
        fit: BoxFit.cover,
      );
    }
    if (value is XFile) {
      avatar = XFileImageWidget(
        image: value,
        height: (MediaQuery.sizeOf(context).height * 0.20).toDouble(),
        width: MediaQuery.sizeOf(context).width.toDouble(),
        fit: BoxFit.cover,
      );
    }
    if (avatar == null) {
      return const SizedBox();
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.elliptical(100, 10),
      ),
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 5,
          sigmaY: 5,
        ),
        child: avatar,
      ),
    );
  }

  Widget renderAvatar(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return Hero(
        tag: 'user-avatar-$value',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(150),
          child: FluxImage(
            imageUrl: value,
            fit: BoxFit.cover,
            width: 150,
            height: 150,
          ),
        ),
      );
    }
    if (value is XFile) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(150),
        child: XFileImageWidget(
          key: ValueKey('user-avatar-${value.name}'),
          image: value,
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        ),
      );
    }
    return const Icon(
      Icons.person,
      size: 120,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context, listen: false);
    return ChangeNotifierProvider<UserUpdateModel>(
      create: (_) => UserUpdateModel(user.user),
      lazy: false,
      child: Consumer<UserUpdateModel>(
        builder: (context, model, child) => Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9.0),
            ),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            onPressed: () async {
              final isConnectNetwork = await context.checkInternet();
              if (isConnectNetwork == false) {
                return;
              }

              if (!formKey.currentState!.validate()) {
                return;
              }
              try {
                final result = await model.updateProfile();
                if (result == null) {
                  return FlashHelper.errorMessage(
                    context,
                    message: S.of(context).updateFailed,
                    duration: const Duration(seconds: 2),
                  );
                }
                unawaited(
                  FlashHelper.message(
                    context,
                    message: S.of(context).updateSuccess,
                    duration: const Duration(seconds: 2),
                  ),
                );
                user.user = User.fromWooJson(
                  result as Map<String, dynamic>,
                  user.user!.cookie,
                );
                await user.setUser(user.user);
                if (mounted) {
                  final navigator = Navigator.of(context);
                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                }
              } catch (e) {
                unawaited(
                  FlashHelper.errorMessage(
                    context,
                    message: '$e',
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            label: Text(
              S.of(context).update,
            ),
          ),
          body: GestureDetector(
            onTap: () {
              Tools.hideKeyboard(context);
            },
            child: Form(
              key: formKey,
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      buildAvatar(model),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                buildInputField(
                                    S.of(context).username, model.username,
                                    isEnabled: false),
                                buildInputField(
                                    S.of(context).email, model.userEmail,
                                    isEnabled: false),
                                buildInputField(S.of(context).displayName,
                                    model.userDisplayName),
                                buildInputField(S.of(context).firstName,
                                    model.userFirstName,
                                    validator: validatorMoreThanThree),
                                buildInputField(
                                    S.of(context).lastName, model.userLastName,
                                    validator: validatorMoreThanThree),
                                buildInputField(
                                    S.of(context).phoneNumber, model.userPhone,
                                    validator: validatorPhone),
                                if (!ServerConfig().isListingType) ...[
                                  buildInputField(S.of(context).streetName,
                                      model.shippingAddress1),
                                  buildInputField(S.of(context).streetNameBlock,
                                      model.shippingAddress2),
                                  buildInputField(
                                      S.of(context).city, model.shippingCity),
                                  buildInputField(S.of(context).stateProvince,
                                      model.shippingState),
                                  buildInputField(S.of(context).country,
                                      model.shippingCountry),
                                  buildInputField(S.of(context).zipCode,
                                      model.shippingPostcode),
                                  buildInputField(
                                      S.of(context).streetNameApartment,
                                      model.shippingCompany),
                                ],
                                const SizedBox(height: 50),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  buildLoading(model),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField(String label, TextEditingController? controller,
      {bool isEnabled = true, Function? validator}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColorLight,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          controller: controller,
          enabled: isEnabled,
          validator: (value) => validator?.call(value, label),
        ),
      ],
    );
  }

  String? validatorMoreThanThree(String? value, String label) {
    if (value == null || value.length < 3) {
      return S.of(context).cannotLessThreeLength(label);
    }
    return null;
  }

  String? validatorPhone(String? value, String label) {
    if (value == null || value.isEmpty) {
      return null;
    }

    const pattern = r'(^(?:[+0])?[0-9]{10,13}$)';
    final regExp = RegExp(pattern);
    if (!regExp.hasMatch(value)) {
      return S.of(context).invalidPhoneNumber;
    }
    return null;
  }

  Widget buildAvatar(UserUpdateModel model) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.25,
      child: Stack(
        children: <Widget>[
          Container(
            height: MediaQuery.sizeOf(context).height * 0.20,
            width: MediaQuery.sizeOf(context).width,
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.elliptical(100, 10),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  )
                ]),
            child: renderBackgroundAvatar(model.avatar),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(150),
                color: Theme.of(context).primaryColorLight,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 3,
                ),
              ),
              child: renderAvatar(model.avatar),
            ),
          ),
          if (Layout.isDisplayDesktop(context) == false)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(left: 75),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(150),
                  color: Theme.of(context).colorScheme.onSurface,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 2,
                  ),
                ),
                height: 40.0,
                width: 40.0,
                child: IconButton(
                  iconSize: 18.0,
                  onPressed: () => model.selectImage(context),
                  icon: Icon(
                    Icons.camera_alt,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
            ),
          SafeArea(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(left: 10),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildLoading(UserUpdateModel model) {
    return model.state == UserUpdateState.loading
        ? Container(
            width: MediaQuery.sizeOf(context).width,
            height: MediaQuery.sizeOf(context).height,
            color: Colors.black.withValueOpacity(0.5),
            child: const Center(
              child: SpinKitCircle(
                color: Colors.white,
                size: 20.0,
              ),
            ),
          )
        : const SizedBox();
  }
}
