import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milestone/core/extensions/context_extensions.dart';
import 'package:milestone/src/auth/presentation/views/register_view.dart';
import 'package:milestone/src/profile/presentation/views/profile_view.dart';

class SignInView extends StatelessWidget {
  const SignInView({super.key});

  static const path = '/login';

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      showPasswordVisibilityToggle: true,
      showAuthActionSwitch: false,
      subtitleBuilder: (_, __) {
        return RichText(
          text: TextSpan(
            text: "Don't have an account? ",
            style: context.theme.textTheme.bodySmall,
            children: [
              TextSpan(
                text: 'Register',
                style: context.theme.textTheme.labelLarge?.copyWith(
                  color: context.theme.colorScheme.primary,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.go(RegisterView.path),
              ),
            ],
          ),
        );
      },
      actions: [
        AuthStateChangeAction<SignedIn>((context, state) {
          if (!state.user!.emailVerified) {
            context.go('/verify-email');
          } else {
            context.go(ProfileView.path);
          }
        }),
        // authFailed,
      ],
    );
  }
}
