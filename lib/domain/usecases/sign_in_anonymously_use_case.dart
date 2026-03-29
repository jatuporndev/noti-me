import '../repositories/auth_repository.dart';

class SignInAnonymouslyUseCase {
  SignInAnonymouslyUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call() => _authRepository.signInAnonymously();
}
