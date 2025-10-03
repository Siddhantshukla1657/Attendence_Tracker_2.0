import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attendence_tracker/models/subject.dart';
import 'package:attendence_tracker/models/attendance.dart';
import 'package:attendence_tracker/models/timetable.dart';

class BackendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authentication methods
  Future<User?> signUp(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('Sign up error: ${e.message}');
      return null;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.message}');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Subjects operations
  Future<void> addSubject(Subject subject) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('subjects')
          .doc(subject.id)
          .set(subject.toJson());
    } catch (e) {
      print('Error adding subject: $e');
    }
  }

  Future<List<Subject>> getSubjects() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('subjects')
          .get();

      return snapshot.docs
          .map((doc) => Subject.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching subjects: $e');
      return [];
    }
  }

  Future<void> updateSubject(Subject subject) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('subjects')
          .doc(subject.id)
          .update(subject.toJson());
    } catch (e) {
      print('Error updating subject: $e');
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('subjects')
          .doc(subjectId)
          .delete();
    } catch (e) {
      print('Error deleting subject: $e');
    }
  }

  // Attendance operations
  Future<void> addAttendanceRecord(AttendanceRecord record) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('attendance')
          .doc(record.id)
          .set(record.toJson());
    } catch (e) {
      print('Error adding attendance record: $e');
    }
  }

  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('attendance')
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                AttendanceRecord.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('Error fetching attendance records: $e');
      return [];
    }
  }

  Future<void> updateAttendanceRecord(AttendanceRecord record) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('attendance')
          .doc(record.id)
          .update(record.toJson());
    } catch (e) {
      print('Error updating attendance record: $e');
    }
  }

  Future<void> deleteAttendanceRecord(String recordId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('attendance')
          .doc(recordId)
          .delete();
    } catch (e) {
      print('Error deleting attendance record: $e');
    }
  }

  // Timetable operations
  Future<void> addTimetable(Timetable timetable) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('timetables')
          .doc(timetable.id)
          .set(timetable.toJson());
    } catch (e) {
      print('Error adding timetable: $e');
    }
  }

  Future<List<Timetable>> getTimetables() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('timetables')
          .get();

      return snapshot.docs
          .map((doc) => Timetable.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching timetables: $e');
      return [];
    }
  }

  Future<void> updateTimetable(Timetable timetable) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('timetables')
          .doc(timetable.id)
          .update(timetable.toJson());
    } catch (e) {
      print('Error updating timetable: $e');
    }
  }

  Future<void> deleteTimetable(String timetableId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('timetables')
          .doc(timetableId)
          .delete();
    } catch (e) {
      print('Error deleting timetable: $e');
    }
  }

  // Sync local data with backend
  Future<void> syncLocalDataWithBackend({
    required List<Subject> subjects,
    required List<AttendanceRecord> attendanceRecords,
    required List<Timetable> timetables,
  }) async {
    try {
      final batch = _firestore.batch();
      final userId = currentUser?.uid;

      if (userId == null) return;

      // Clear existing data
      final subjectsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .get();

      final attendanceSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .get();

      final timetablesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('timetables')
          .get();

      // Delete existing data
      for (final doc in subjectsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      for (final doc in attendanceSnapshot.docs) {
        batch.delete(doc.reference);
      }

      for (final doc in timetablesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Add new data
      for (final subject in subjects) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('subjects')
            .doc(subject.id);
        batch.set(docRef, subject.toJson());
      }

      for (final record in attendanceRecords) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('attendance')
            .doc(record.id);
        batch.set(docRef, record.toJson());
      }

      for (final timetable in timetables) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('timetables')
            .doc(timetable.id);
        batch.set(docRef, timetable.toJson());
      }

      await batch.commit();
      print('Data synced successfully with backend');
    } catch (e) {
      print('Error syncing data with backend: $e');
    }
  }
}
