import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/domain/entities/user_profile.dart';
import 'package:noti_me/domain/usecases/sign_out_use_case.dart';
import 'package:noti_me/domain/usecases/update_nickname_use_case.dart';
import 'package:noti_me/domain/usecases/watch_user_profile_use_case.dart';

import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required String uid,
    required WatchUserProfileUseCase watchUserProfile,
    required UpdateNicknameUseCase updateNickname,
    required SignOutUseCase signOut,
  })  : _uid = uid,
        _updateNickname = updateNickname,
        _signOut = signOut,
        super(const ProfileLoading()) {
    _subscription = watchUserProfile(_uid).listen(
      (profile) => emit(ProfileLoaded(profile)),
      onError: (Object e) => emit(ProfileStreamError(e.toString())),
    );
  }

  final String _uid;
  final UpdateNicknameUseCase _updateNickname;
  final SignOutUseCase _signOut;

  late final StreamSubscription<UserProfile> _subscription;

  Future<void> saveNickname(String nickname) async {
    await _updateNickname(_uid, nickname);
  }

  Future<void> signOut() => _signOut();

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
