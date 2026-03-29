import 'package:equatable/equatable.dart';

/// Signed-in user visible to the presentation layer (no Firebase types).
class SessionUser extends Equatable {
  const SessionUser({
    required this.uid,
    required this.isAnonymous,
    this.email,
    this.displayName,
  });

  final String uid;
  final bool isAnonymous;
  final String? email;
  final String? displayName;

  @override
  List<Object?> get props => [uid, isAnonymous, email, displayName];
}
