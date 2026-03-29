import '../entities/session_user.dart';
import '../repositories/user_repository.dart';

class EnsureUserDocumentUseCase {
  EnsureUserDocumentUseCase(this._userRepository);

  final UserRepository _userRepository;

  Future<void> call(SessionUser user) =>
      _userRepository.ensureUserDocument(user);
}
