import 'dart:math';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/isar_database.dart';
import '../database/schemas/meeting_models.dart';
import '../providers/app_providers.dart';
import '../services/firestore_service.dart';

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
  final Ref _ref;
  final Random _random = Random();
  IsarMeetingRepository(this._ref);

  Isar get _isar => IsarDatabase.instance.isar;

  String get _currentUserId {
    final uid = _ref.read(authRepositoryProvider).currentUser?.uid;
    return uid ?? 'offline_fallback';
  }

  int _generateUniqueIntId() {
    return (DateTime.now().microsecondsSinceEpoch + _random.nextInt(1000)) & 0x7FFFFFFFFFFFFFFF;
  }

  @override
  Future<List<MeetingModel>> getAllMeetings() async {
    return await _isar.meetingModels
        .filter()
        .userIdEqualTo(_currentUserId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  @override
  Stream<List<MeetingModel>> watchMeetings() {
    return _isar.meetingModels
        .filter()
        .userIdEqualTo(_currentUserId)
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  @override
  Future<MeetingModel?> getMeetingById(int id) async {
    final meeting = await _isar.meetingModels.get(id);
    if (meeting != null && meeting.userId == _currentUserId) {
      await meeting.transcript.load();
      if (meeting.transcript.value != null) {
        await meeting.transcript.value!.segments.load();
      }
      await meeting.summary.load();
      await meeting.actionItems.load();
      await meeting.decisions.load();
      await meeting.chatMessages.load();
      return meeting;
    }
    return null;
  }

  @override
  Stream<MeetingModel?> watchMeetingById(int id) {
    return _isar.meetingModels.watchObject(id, fireImmediately: true).asyncMap((meeting) async {
      if (meeting != null && meeting.userId == _currentUserId) {
        await meeting.transcript.load();
        if (meeting.transcript.value != null) {
          await meeting.transcript.value!.segments.load();
        }
        await meeting.summary.load();
        await meeting.actionItems.load();
        await meeting.decisions.load();
        await meeting.chatMessages.load();
        return meeting;
      }
      return null;
    });
  }

  @override
  Future<MeetingModel> createMeeting(String title) async {
    final currentUid = _currentUserId;
    final generatedMeetingId = _generateUniqueIntId();
    final generatedTranscriptId = _generateUniqueIntId();

    final meeting = MeetingModel()
      ..id = generatedMeetingId
      ..title = title
      ..createdAt = DateTime.now()
      ..durationSeconds = 0.0
      ..isRecording = true
      ..isSynced = false
      ..userId = currentUid;

    final transcript = TranscriptModel()
      ..id = generatedTranscriptId
      ..userId = currentUid;

    await _isar.writeTxn(() async {
      await _isar.transcriptModels.put(transcript);
      meeting.transcript.value = transcript;
      await _isar.meetingModels.put(meeting);
      await meeting.transcript.save();
    });

    FirestoreService.instance.saveMeeting(meeting, currentUid).catchError((e) {
      print("[MeetingRepository ERROR] createMeeting Firestore sync failed: $e");
    });

    return meeting;
  }

  @override
  Future<void> updateMeeting(MeetingModel meeting) async {
    if (meeting.userId != _currentUserId) return;
    await _isar.writeTxn(() async {
      await _isar.meetingModels.put(meeting);
    });
    FirestoreService.instance.saveMeeting(meeting, _currentUserId).catchError((e) {
      print("[MeetingRepository ERROR] updateMeeting Firestore sync failed: $e");
    });
  }

  @override
  Future<void> deleteMeeting(int id) async {
    final meeting = await getMeetingById(id);
    if (meeting == null || meeting.userId != _currentUserId) return;

    FirestoreService.instance.deleteMeeting(id, _currentUserId).catchError((e) {
      print("[MeetingRepository ERROR] deleteMeeting Firestore sync failed: $e");
    });

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
      final currentUid = _currentUserId;
      for (final item in meeting.actionItems) {
        await _isar.actionItemModels.delete(item.id);
        FirestoreService.instance.deleteTask(item.id, currentUid).catchError((e) {
          print("[MeetingRepository ERROR] deleteTask Firestore sync failed: $e");
        });
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
    if (meeting == null || meeting.userId != _currentUserId) return;

    await meeting.transcript.load();
    final transcript = meeting.transcript.value;
    if (transcript == null) return;

    final currentUid = _currentUserId;
    await _isar.writeTxn(() async {
      segment.id = _generateUniqueIntId();
      segment.transcript.value = transcript;
      segment.userId = currentUid;
      await _isar.transcriptSegmentModels.put(segment);
      await segment.transcript.save();
      
      // Update meeting duration to match the end time of the last segment
      if (segment.endTime > meeting.durationSeconds) {
        meeting.durationSeconds = segment.endTime;
      }
      await _isar.meetingModels.put(meeting);
    });

    FirestoreService.instance.saveMeeting(meeting, currentUid).catchError((e) {
      print("[MeetingRepository ERROR] addTranscriptSegment Firestore sync failed: $e");
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
      if (meeting == null || meeting.userId != _currentUserId) {
        print("[MeetingRepository ERROR] Meeting not found in database or unauthorized for ID: $meetingId");
        return;
      }

      final currentUid = _currentUserId;
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
          FirestoreService.instance.deleteTask(item.id, currentUid).catchError((e) {
            print("[MeetingRepository ERROR] deleteTask Firestore sync failed: $e");
          });
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
        summary.id = _generateUniqueIntId();
        summary.userId = currentUid;
        await _isar.summaryModels.put(summary);
        meeting.summary.value = summary;

        // 5. Save new action items
        print("[MeetingRepository] Saving ${actionItems.length} new ActionItemModels...");
        for (final item in actionItems) {
          item.id = _generateUniqueIntId();
          item.meeting.value = meeting;
          item.userId = currentUid;
          await _isar.actionItemModels.put(item);
          meeting.actionItems.add(item);
        }

        // 6. Save new decisions
        print("[MeetingRepository] Saving ${decisions.length} new DecisionModels...");
        for (final decision in decisions) {
          decision.id = _generateUniqueIntId();
          decision.meeting.value = meeting;
          decision.userId = currentUid;
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

      FirestoreService.instance.saveMeeting(meeting, currentUid).catchError((e) {
        print("[MeetingRepository ERROR] saveSummaryAndActionItems Firestore sync failed: $e");
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
    if (meeting == null || meeting.userId != _currentUserId) return;

    final currentUid = _currentUserId;
    await _isar.writeTxn(() async {
      message.id = _generateUniqueIntId();
      message.meeting.value = meeting;
      message.userId = currentUid;
      await _isar.chatMessageModels.put(message);
      await message.meeting.save();
    });
  }
}
