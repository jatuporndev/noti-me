import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/domain/usecases/sign_in_anonymously_use_case.dart';
import 'package:noti_me/domain/usecases/sign_in_with_google_use_case.dart';

import 'sign_in_state.dart';

class SignInCubit extends Cubit<SignInState> {
  SignInCubit({
    required SignInWithGoogleUseCase signInWithGoogle,
    required SignInAnonymouslyUseCase signInAnonymously,
  })  : _signInWithGoogle = signInWithGoogle,
        _signInAnonymously = signInAnonymously,
        super(const SignInState());

  final SignInWithGoogleUseCase _signInWithGoogle;
  final SignInAnonymouslyUseCase _signInAnonymously;

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      await _signInWithGoogle();
      emit(state.copyWith(submitting: false));
    } catch (e) {
      emit(
        state.copyWith(
          submitting: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> signInAnonymously() async {
    emit(state.copyWith(submitting: true, clearError: true));
    try {
      await _signInAnonymously();
      emit(state.copyWith(submitting: false));
    } catch (e) {
      emit(
        state.copyWith(
          submitting: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
