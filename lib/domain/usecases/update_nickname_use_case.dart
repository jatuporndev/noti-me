import '../repositories/user_repository.dart';

class UpdateNicknameUseCase {
  UpdateNicknameUseCase(this._userRepository);

  final UserRepository _userRepository;

  Future<void> call(String uid, String nickname) =>
      _userRepository.updateNickname(uid, nickname);
}
