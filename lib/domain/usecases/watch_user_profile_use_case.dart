import '../entities/user_profile.dart';
import '../repositories/user_repository.dart';

class WatchUserProfileUseCase {
  WatchUserProfileUseCase(this._userRepository);

  final UserRepository _userRepository;

  Stream<UserProfile> call(String uid) =>
      _userRepository.watchUserProfile(uid);
}
