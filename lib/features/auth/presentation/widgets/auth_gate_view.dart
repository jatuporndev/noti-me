import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/core/di/service_locator.dart';
import 'package:noti_me/features/home/presentation/screens/home_screen.dart';

import '../bloc/auth_session/auth_session_cubit.dart';
import '../bloc/auth_session/auth_session_state.dart';
import '../bloc/sign_in/sign_in_cubit.dart';
import '../screens/sign_in_screen.dart';

class AuthGateView extends StatelessWidget {
  const AuthGateView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthSessionCubit, AuthSessionState>(
      builder: (context, state) {
        return switch (state) {
          AuthSessionLoading() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          AuthSessionSignedOut() => BlocProvider(
              create: (_) => sl<SignInCubit>(),
              child: const SignInScreen(),
            ),
          AuthSessionBootstrapping() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          AuthSessionReady(:final user) => HomeScreen(user: user),
          AuthSessionBootstrapFailure(:final error) => Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Could not finish setup',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$error',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () =>
                            context.read<AuthSessionCubit>().retryBootstrap(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        };
      },
    );
  }
}
