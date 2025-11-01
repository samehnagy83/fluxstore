import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:fstore/common/constants.dart';

import '../../realtime_chat.dart';

class WcfmLiveChatAuth extends StatefulWidget {
  const WcfmLiveChatAuth({
    super.key,
    required this.chatArgs,
  });

  final ChatArgs chatArgs;

  @override
  State<WcfmLiveChatAuth> createState() => _WcfmLiveChatAuthState();
}

class _WcfmLiveChatAuthState extends State<WcfmLiveChatAuth> {
  ChatArgs get chatArgs => widget.chatArgs;
  ChatUser get sender => chatArgs.sender;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameEditingController =
      TextEditingController();
  final TextEditingController _emailEditingController = TextEditingController();

  void _onStartChat() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final newSender = sender.copyWith(
      email: _emailEditingController.text,
      name: _usernameEditingController.text,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RealtimeChat(
          chatArgs: chatArgs.copyWith(
            sender: newSender,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _usernameEditingController.text = sender.name ?? '';
    _emailEditingController.text = sender.email ?? '';
  }

  @override
  void dispose() {
    _usernameEditingController.dispose();
    _emailEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
        ),
        margin: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 450.0,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(10.0),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 24.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    S.of(context).chatNow,
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12.0),
                  Text(S.of(context).haveYouGotQuestion),
                  const SizedBox(height: 24.0),
                  TextFormField(
                    controller: _usernameEditingController,
                    decoration: InputDecoration(
                      labelText: S.of(context).name,
                      hintText: S.of(context).enterYourName,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return S.of(context).nameIsRequired;
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _emailEditingController,
                    decoration: InputDecoration(
                      labelText: S.of(context).email,
                      hintText: S.of(context).enterYourEmail,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return S.of(context).emailIsRequired;
                      }
                      if (!value.isEmail) {
                        return S.of(context).emailAddressInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24.0),
                  if (sender.id == null) ...[
                    Text.rich(
                      TextSpan(
                        text: '*',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: S.of(context).notLoggedInLiveChatWarning,
                            style: textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      textScaler: const TextScaler.linear(0.8),
                    ),
                    const SizedBox(height: 12.0),
                  ],
                  ElevatedButton(
                    onPressed: _onStartChat,
                    child: Text(S.of(context).startChat),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
