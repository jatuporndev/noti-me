import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:noti_me/domain/entities/channel.dart';
import 'package:noti_me/domain/entities/channel_member.dart';
import 'package:noti_me/domain/entities/reminder.dart';
import 'package:noti_me/domain/repositories/channel_repository.dart';
import 'package:noti_me/domain/repositories/reminder_repository.dart';

import 'channel_detail_state.dart';

class ChannelDetailCubit extends Cubit<ChannelDetailState> {
  ChannelDetailCubit({
    required ChannelRepository channelRepository,
    required ReminderRepository reminderRepository,
    required String channelId,
  })  : _channelRepository = channelRepository,
        _reminderRepository = reminderRepository,
        _channelId = channelId,
        super(const ChannelDetailLoading()) {
    _channelSub = _channelRepository.watchChannel(channelId).listen(
      (channel) {
        _latestChannel = channel;
        _emitIfReady();
      },
      onError: (Object e) => emit(ChannelDetailError('$e')),
    );
    _membersSub = _channelRepository.watchMembers(channelId).listen(
      (members) {
        _latestMembers = members;
        _emitIfReady();
      },
      onError: (Object e) => emit(ChannelDetailError('$e')),
    );
    _remindersSub = _reminderRepository.watchReminders(channelId).listen(
      (reminders) {
        _latestReminders = reminders;
        _emitIfReady();
      },
      onError: (Object e) => emit(ChannelDetailError('$e')),
    );
  }

  final ChannelRepository _channelRepository;
  final ReminderRepository _reminderRepository;
  final String _channelId;

  late final StreamSubscription<Channel> _channelSub;
  late final StreamSubscription<List<ChannelMember>> _membersSub;
  late final StreamSubscription<List<Reminder>> _remindersSub;

  Channel? _latestChannel;
  List<ChannelMember>? _latestMembers;
  List<Reminder>? _latestReminders;

  void _emitIfReady() {
    final ch = _latestChannel;
    final mem = _latestMembers;
    final rem = _latestReminders;
    if (ch != null && mem != null && rem != null) {
      emit(ChannelDetailLoaded(channel: ch, members: mem, reminders: rem));
    }
  }

  Future<void> toggleMute(String uid, bool muted) =>
      _channelRepository.updateMemberMute(_channelId, uid, muted);

  Future<void> setMemberCanEdit({
    required String callerUid,
    required String targetUid,
    required bool canEdit,
  }) =>
      _channelRepository.setMemberCanEdit(
        channelId: _channelId,
        callerUid: callerUid,
        targetUid: targetUid,
        canEdit: canEdit,
      );

  Future<void> deleteChannel(String uid) =>
      _channelRepository.deleteChannel(_channelId, uid);

  Future<void> leaveChannel(String uid) =>
      _channelRepository.leaveChannel(channelId: _channelId, uid: uid);

  Future<void> updateNotificationSchedule({
    required String uid,
    required List<String> notifySlots,
    required String notifyStartDateBangkok,
    required bool repeatDaily,
  }) =>
      _channelRepository.updateChannelNotificationSchedule(
        channelId: _channelId,
        uid: uid,
        notifySlots: notifySlots,
        notifyStartDateBangkok: notifyStartDateBangkok,
        repeatDaily: repeatDaily,
      );

  Future<void> createReminder({
    required String title,
    String? body,
    required String createdByUid,
  }) =>
      _reminderRepository.createReminder(
        channelId: _channelId,
        title: title,
        body: body,
        createdByUid: createdByUid,
      );

  Future<void> deleteReminder(String reminderId) =>
      _reminderRepository.deleteReminder(_channelId, reminderId);

  @override
  Future<void> close() {
    _channelSub.cancel();
    _membersSub.cancel();
    _remindersSub.cancel();
    return super.close();
  }
}
