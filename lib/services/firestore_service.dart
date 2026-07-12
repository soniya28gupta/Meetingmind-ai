import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../database/schemas/meeting_models.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._internal();
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- USER PROFILE ---
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
      debugPrint('[FirestoreService] Saved user profile for $uid');
    } catch (e) {
      debugPrint('[FirestoreService ERROR] saveUserProfile failed: $e');
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserProfile(
    String uid,
  ) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc;
    } catch (e) {
      debugPrint('[FirestoreService ERROR] getUserProfile failed: $e');
      return null;
    }
  }

  // --- MEETINGS ---
  Future<void> saveMeeting(MeetingModel meeting, String userId) async {
    try {
      final meetingDocRef = _db
          .collection('meetings')
          .doc(meeting.id.toString());

      // Load transcript and summary if not loaded
      await meeting.transcript.load();
      await meeting.summary.load();
      await meeting.actionItems.load();
      await meeting.decisions.load();

      final summaryVal = meeting.summary.value;
      final transcriptVal = meeting.transcript.value;

      final Map<String, dynamic> meetingData = {
        'id': meeting.id,
        'userId': userId,
        'title': meeting.title,
        'createdAt': meeting.createdAt != null
            ? Timestamp.fromDate(meeting.createdAt!)
            : null,
        'durationSeconds': meeting.durationSeconds,
        'audioFilePath': meeting.audioFilePath,
        'detectedEmotion': meeting.detectedEmotion,
        'emotionConfidence': meeting.emotionConfidence,
        'isRecording': meeting.isRecording,
        'summary': summaryVal != null
            ? {
                'executiveSummary': summaryVal.executiveSummary,
                'meetingNotes': summaryVal.meetingNotes,
                'keyTakeaways': summaryVal.keyTakeaways,
                'followUps': summaryVal.followUps,
                'risks': summaryVal.risks,
                'deadlines': summaryVal.deadlines,
              }
            : null,
        'decisions': meeting.decisions.map((d) => d.description).toList(),
      };

      await meetingDocRef.set(meetingData, SetOptions(merge: true));

      // Save transcript segments
      if (transcriptVal != null) {
        await transcriptVal.segments.load();
        final segmentsColl = meetingDocRef.collection('segments');
        for (final seg in transcriptVal.segments) {
          await segmentsColl.doc(seg.id.toString()).set({
            'id': seg.id,
            'speaker': seg.speaker,
            'text': seg.text,
            'startTime': seg.startTime,
            'endTime': seg.endTime,
          }, SetOptions(merge: true));
        }
      }

      // Sync associated tasks (action items)
      for (final task in meeting.actionItems) {
        await saveTask(task, userId);
      }

      debugPrint(
        '[FirestoreService] Synced meeting ${meeting.id} to Firestore',
      );
    } catch (e) {
      debugPrint('[FirestoreService ERROR] saveMeeting failed: $e');
    }
  }

  Future<void> deleteMeeting(int meetingId, String userId) async {
    try {
      final docRef = _db.collection('meetings').doc(meetingId.toString());

      // Delete segments subcollection
      final segments = await docRef.collection('segments').get();
      for (final doc in segments.docs) {
        await doc.reference.delete();
      }

      await docRef.delete();
      debugPrint(
        '[FirestoreService] Deleted meeting $meetingId from Firestore',
      );
    } catch (e) {
      debugPrint('[FirestoreService ERROR] deleteMeeting failed: $e');
    }
  }

  // --- TASKS ---
  Future<void> saveTask(ActionItemModel task, String userId) async {
    try {
      await task.meeting.load();
      await _db.collection('tasks').doc(task.id.toString()).set({
        'id': task.id,
        'userId': userId,
        'meetingId': task.meeting.value?.id,
        'description': task.description,
        'deadline': task.deadline != null
            ? Timestamp.fromDate(task.deadline!)
            : null,
        'isCompleted': task.isCompleted,
        'assignedTo': task.assignedTo,
        'priority': task.priority,
      }, SetOptions(merge: true));
      debugPrint('[FirestoreService] Synced task ${task.id} to Firestore');
    } catch (e) {
      debugPrint('[FirestoreService ERROR] saveTask failed: $e');
    }
  }

  Future<void> deleteTask(int taskId, String userId) async {
    try {
      await _db.collection('tasks').doc(taskId.toString()).delete();
      debugPrint('[FirestoreService] Deleted task $taskId from Firestore');
    } catch (e) {
      debugPrint('[FirestoreService ERROR] deleteTask failed: $e');
    }
  }

  // --- ACTIVITY LOGS ---
  Future<void> saveActivity(
    DateTime date,
    double durationSeconds,
    String userId,
  ) async {
    try {
      final dateKey =
          '${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}';
      final docId = '${userId}_$dateKey';

      await _db.collection('activity').doc(docId).set({
        'docId': docId,
        'userId': userId,
        'date': Timestamp.fromDate(date),
        'durationSeconds': durationSeconds,
      }, SetOptions(merge: true));
      debugPrint('[FirestoreService] Synced activity $docId to Firestore');
    } catch (e) {
      debugPrint('[FirestoreService ERROR] saveActivity failed: $e');
    }
  }
}
