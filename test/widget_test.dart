import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noti_me/domain/entities/session_user.dart';
import 'package:noti_me/domain/repositories/auth_repository.dart';
import 'package:noti_me/domain/usecases/sign_in_anonymously_use_case.dart';
import 'package:noti_me/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:noti_me/features/auth/presentation/bloc/sign_in/sign_in_cubit.dart';
import 'package:noti_me/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:noti_me/core/theme/app_theme.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<SessionUser?> watchAuthState() => Stream<SessionUser?>.empty();

  @override
  SessionUser? get currentUser => null;

  @override
  Future<void> signInAnonymously() async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('Sign-in screen shows title', (WidgetTester tester) async {
    final auth = _FakeAuthRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNotiMeTheme(),
        home: BlocProvider(
          create: (_) => SignInCubit(
            signInWithGoogle: SignInWithGoogleUseCase(auth),
            signInAnonymously: SignInAnonymouslyUseCase(auth),
          ),
          child: const SignInScreen(),
        ),
      ),
    );

    expect(find.text('notiMe'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
