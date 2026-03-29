import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/core/theme/app_theme.dart';
import 'package:noti_me/features/auth/presentation/bloc/auth_session/auth_session_cubit.dart';
import 'package:noti_me/features/auth/presentation/widgets/auth_gate_view.dart';

class NotiMeApp extends StatelessWidget {
  const NotiMeApp({super.key, required this.authSessionCubit});

  final AuthSessionCubit authSessionCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: authSessionCubit,
      child: MaterialApp(
        title: 'notiMe',
        theme: buildNotiMeTheme(),
        home: const AuthGateView(),
      ),
    );
  }
}
