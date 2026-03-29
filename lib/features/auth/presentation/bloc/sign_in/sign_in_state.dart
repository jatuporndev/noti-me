import 'package:equatable/equatable.dart';

final class SignInState extends Equatable {
  const SignInState({
    this.submitting = false,
    this.errorMessage,
  });

  final bool submitting;
  final String? errorMessage;

  SignInState copyWith({
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SignInState(
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [submitting, errorMessage];
}
