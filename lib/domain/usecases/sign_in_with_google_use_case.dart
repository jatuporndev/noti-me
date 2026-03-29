import '../repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  SignInWithGoogleUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call() => _authRepository.signInWithGoogle();
}
