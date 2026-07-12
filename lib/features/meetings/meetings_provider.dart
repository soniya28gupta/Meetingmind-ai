import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/schemas/meeting_models.dart';
import '../../providers/app_providers.dart';

// Stream of all meetings
final meetingsListStreamProvider = StreamProvider<List<MeetingModel>>((ref) {
  return ref.watch(meetingRepositoryProvider).watchMeetings();
});

// Future of a single meeting by its ID
final meetingDetailsFutureProvider = FutureProvider.family<MeetingModel?, int>((
  ref,
  id,
) async {
  return await ref.watch(meetingRepositoryProvider).getMeetingById(id);
});

// Stream of a single meeting by its ID (allows real-time live UI updates)
final meetingDetailsStreamProvider = StreamProvider.family<MeetingModel?, int>((
  ref,
  id,
) {
  return ref.watch(meetingRepositoryProvider).watchMeetingById(id);
});

// Notifier to trigger meeting operations (like deleting or re-running sync)
class MeetingsController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  MeetingsController(this._ref) : super(const AsyncValue.data(null));

  Future<void> deleteMeeting(int meetingId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _ref.read(meetingRepositoryProvider).deleteMeeting(meetingId);
      // Invalidate details provider to free memory/cache
      _ref.invalidate(meetingDetailsFutureProvider(meetingId));
    });
  }
}

final meetingsControllerProvider =
    StateNotifierProvider<MeetingsController, AsyncValue<void>>((ref) {
      return MeetingsController(ref);
    });
