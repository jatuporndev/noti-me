import '../entities/session_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentSessionUserUseCase {
  GetCurrentSessionUserUseCase(this._authRepository);

  final AuthRepository _authRepository;

  SessionUser? call() => _authRepository.currentUser;
}
