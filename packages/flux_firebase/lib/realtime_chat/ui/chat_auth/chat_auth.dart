import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:fstore/common/constants.dart';
import 'package:fstore/common/events.dart';

class ChatAuth extends StatelessWidget {
  const ChatAuth({super.key});

  void _handleLogin() async {
    eventBus.fire(
      const EventExpiredCookie(
        isRequiredLogin: true,
        skipDuplicateCheck: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
      ),
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
            horizontal: 48.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16.0),
              Text(
                S.of(context).sessionExpired,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 16.0),
              Text(
                S.of(context).loginToContinue,
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _handleLogin,
                child: Text(S.of(context).signIn),
              ),
              const SizedBox(height: 16.0),
              if (context.navigator.canPop())
                TextButton(
                  onPressed: () {
                    context.navigator.pop();
                  },
                  child: Text(S.of(context).goBack),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
