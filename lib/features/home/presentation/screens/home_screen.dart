import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/core/di/service_locator.dart';
import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/domain/entities/session_user.dart';
import 'package:noti_me/features/user/presentation/bloc/profile/profile_cubit.dart';
import 'package:noti_me/features/user/presentation/screens/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});

  final SessionUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('notiMe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => _openProfile(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'You are signed in.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                user.isAnonymous
                    ? 'Guest account'
                    : (user.email ?? user.displayName ?? 'Google user'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _openProfile(context),
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Profile & tag'),
                style: FilledButton.styleFrom(
                  backgroundColor: kNotiMePrimary,
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => ProfileCubit(
            uid: user.uid,
            watchUserProfile: sl(),
            updateNickname: sl(),
            signOut: sl(),
          ),
          child: const ProfileScreen(),
        ),
      ),
    );
  }
}
