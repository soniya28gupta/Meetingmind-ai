import 'package:isar/isar.dart';
import '../database/isar_database.dart';
import '../database/schemas/meeting_models.dart';

abstract class MeetingRepository {
  Future<List<MeetingModel>> getAllMeetings();
  Stream<List<MeetingModel>> watchMeetings();
  Future<MeetingModel?> getMeetingById(int id);
  Stream<MeetingModel?> watchMeetingById(int id);
  Future<MeetingModel> createMeeting(String title);
  Future<void> updateMeeting(MeetingModel meeting);
  Future<void> deleteMeeting(int id);
  
  // Real-time transcript updates
  Future<void> addTranscriptSegment(int meetingId, TranscriptSegmentModel segment);
  
  // Summary, action items, and decisions save
  Future<void> saveSummaryAndActionItems(
    int meetingId,
    SummaryModel summary,
    List<ActionItemModel> actionItems,
    List<DecisionModel> decisions,
  );

  // Chat message management
  Future<void> addChatMessage(int meetingId, ChatMessageModel message);
}

class IsarMeetingRepository implements MeetingRepository {
  Isar get _isar => IsarDatabase.instance.isar;

  @override
  Future<List<MeetingModel>> getAllMeetings() async {
    return await _isar.meetingModels.where().sortByCreatedAtDesc().findAll();
  }

  @override
  Stream<List<MeetingModel>> watchMeetings() {
    return _isar.meetingModels.where().sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  @override
  Future<MeetingModel?> getMeetingById(int id) async {
    final meeting = await _isar.meetingModels.get(id);
    if (meeting != null) {
      await meeting.transcript.load();
      if (meeting.transcript.value != null) {
        await meeting.transcript.value!.segments.load();
      }
      await meeting.summary.load();
      await meeting.actionItems.load();
      await meeting.decisions.load();
      await meeting.chatMessages.load();
    }
    return meeting;
  }

  @override
  Stream<MeetingModel?> watchMeetingById(int id) {
    return _isar.meetingModels.watchObject(id, fireImmediately: true).asyncMap((meeting) async {
      if (meeting != null) {
        await meeting.transcript.load();
        if (meeting.transcript.value != null) {
          await meeting.transcript.value!.segments.load();
        }
        await meeting.summary.load();
        await meeting.actionItems.load();
        await meeting.decisions.load();
        await meeting.chatMessages.load();
      }
      return meeting;
    });
  }

  @override
  Future<MeetingModel> createMeeting(String title) async {
    final meeting = MeetingModel()
      ..title = title
      ..createdAt = DateTime.now()
      ..durationSeconds = 0.0
      ..isRecording = true
      ..isSynced = false;

    final transcript = TranscriptModel();

    await _isar.writeTxn(() async {
      await _isar.transcriptModels.put(transcript);
      meeting.transcript.value = transcript;
      await _isar.meetingModels.put(meeting);
      await meeting.transcript.save();
    });

    return meeting;
  }

  @override
  Future<void> updateMeeting(MeetingModel meeting) async {
    await _isar.writeTxn(() async {
      await _isar.meetingModels.put(meeting);
    });
  }

  @override
  Future<void> deleteMeeting(int id) async {
    final meeting = await getMeetingById(id);
    if (meeting == null) return;

    await _isar.writeTxn(() async {
      // Delete segments and transcript
      if (meeting.transcript.value != null) {
        final segments = meeting.transcript.value!.segments.toList();
        for (final segment in segments) {
          await _isar.transcriptSegmentModels.delete(segment.id);
        }
        await _isar.transcriptModels.delete(meeting.transcript.value!.id);
      }

      // Delete summary
      if (meeting.summary.value != null) {
        await _isar.summaryModels.delete(meeting.summary.value!.id);
      }

      // Delete action items, decisions, and chat messages
      for (final item in meeting.actionItems) {
        await _isar.actionItemModels.delete(item.id);
      }
      for (final decision in meeting.decisions) {
        await _isar.decisionModels.delete(decision.id);
      }
      for (final chat in meeting.chatMessages) {
        await _isar.chatMessageModels.delete(chat.id);
      }

      // Delete the meeting itself
      await _isar.meetingModels.delete(meeting.id);
    });
  }

  @override
  Future<void> addTranscriptSegment(int meetingId, TranscriptSegmentModel segment) async {
    final meeting = await _isar.meetingModels.get(meetingId);
    if (meeting == null) return;

    await meeting.transcript.load();
    final transcript = meeting.transcript.value;
    if (transcript == null) return;

    await _isar.writeTxn(() async {
      segment.transcript.value = transcript;
      await _isar.transcriptSegmentModels.put(segment);
      await segment.transcript.save();
      
      // Update meeting duration to match the end time of the last segment
      if (segment.endTime > meeting.durationSeconds) {
        meeting.durationSeconds = segment.endTime;
      }
      await _isar.meetingModels.put(meeting);
    });
  }

  @override
  Future<void> saveSummaryAndActionItems(
    int meetingId,
    SummaryModel summary,
    List<ActionItemModel> actionItems,
    List<DecisionModel> decisions,
  ) async {
    print("[MeetingRepository] saveSummaryAndActionItems started for meeting ID: $meetingId");
    try {
      final meeting = await getMeetingById(meetingId);
      if (meeting == null) {
        print("[MeetingRepository ERROR] Meeting not found in database for ID: $meetingId");
        return;
      }

      print("[MeetingRepository] Deleting previous summary, action items, and decisions...");
      await _isar.writeTxn(() async {
        // 1. Delete previous summary if exists
        if (meeting.summary.value != null) {
          await _isar.summaryModels.delete(meeting.summary.value!.id);
        }
        
        // 2. Delete previous action items
        final oldActionItems = meeting.actionItems.toList();
        for (final item in oldActionItems) {
          await _isar.actionItemModels.delete(item.id);
        }
        meeting.actionItems.clear();

        // 3. Delete previous decisions
        final oldDecisions = meeting.decisions.toList();
        for (final decision in oldDecisions) {
          await _isar.decisionModels.delete(decision.id);
        }
        meeting.decisions.clear();

        // 4. Save new summary
        print("[MeetingRepository] Saving new SummaryModel...");
        await _isar.summaryModels.put(summary);
        meeting.summary.value = summary;

        // 5. Save new action items
        print("[MeetingRepository] Saving ${actionItems.length} new ActionItemModels...");
        for (final item in actionItems) {
          item.meeting.value = meeting;
          await _isar.actionItemModels.put(item);
          meeting.actionItems.add(item);
        }

        // 6. Save new decisions
        print("[MeetingRepository] Saving ${decisions.length} new DecisionModels...");
        for (final decision in decisions) {
          decision.meeting.value = meeting;
          await _isar.decisionModels.put(decision);
          meeting.decisions.add(decision);
        }

        // 7. Save meeting properties
        meeting.isSynced = false;
        await _isar.meetingModels.put(meeting);

        // 8. Save relationships
        await meeting.summary.save();
        await meeting.actionItems.save();
        await meeting.decisions.save();
      });
      print("[MeetingRepository] saveSummaryAndActionItems completed successfully.");
    } catch (e, stack) {
      print("[MeetingRepository ERROR] saveSummaryAndActionItems failed: $e");
      print(stack);
      rethrow;
    }
  }

  @override
  Future<void> addChatMessage(int meetingId, ChatMessageModel message) async {
    final meeting = await _isar.meetingModels.get(meetingId);
    if (meeting == null) return;

    await _isar.writeTxn(() async {
      message.meeting.value = meeting;
      await _isar.chatMessageModels.put(message);
      await message.meeting.save();
    });
  }
}
