import '../repositories/auth_repository.dart';

class SignOutUseCase {
  SignOutUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call() => _authRepository.signOut();
}
