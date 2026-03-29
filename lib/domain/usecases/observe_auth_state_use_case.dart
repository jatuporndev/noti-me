import '../entities/session_user.dart';
import '../repositories/auth_repository.dart';

class ObserveAuthStateUseCase {
  ObserveAuthStateUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Stream<SessionUser?> call() => _authRepository.watchAuthState();
}
