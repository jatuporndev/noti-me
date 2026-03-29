import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:noti_me/core/di/service_locator.dart';
import 'package:noti_me/core/theme/app_theme.dart';
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
          AuthSessionLoading() => const _AppLoadingScreen(),
          AuthSessionSignedOut() => BlocProvider(
              create: (_) => sl<SignInCubit>(),
              child: const SignInScreen(),
            ),
          AuthSessionBootstrapping() => const _AppLoadingScreen(),
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

/// Full-screen loading shown while Firebase auth stream initialises or
/// while the user document is being bootstrapped after sign-in.
class _AppLoadingScreen extends StatelessWidget {
  const _AppLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Skeletonizer(
              enabled: true,
              effect: const ShimmerEffect(
                baseColor: Color(0xFFFFE5B4),
                highlightColor: Color(0xFFFFF8EE),
                duration: Duration(milliseconds: 1200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Big card — the skeleton shimmers over this whole block
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Skeletonizer replaces raster images with a plain bone rect;
                          // keep the real mascot visible on the loading gate.
                          Skeleton.keep(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/catcos.jpg',
                                width: 148,
                                height: 148,
                                fit: BoxFit.cover,
                                color: kNotiMePrimary,
                                colorBlendMode: BlendMode.modulate,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'notiMe',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontFamily: kMonoFontFamily,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'never forget stuff again',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.black38),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Skeleton placeholder rows below the card
                  Container(
                    height: 14,
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 14,
                    width: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(7),
                    ),
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
