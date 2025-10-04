import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:attendence_tracker/models/subject.dart';
import 'package:attendence_tracker/models/attendance.dart';
import 'package:attendence_tracker/models/timetable.dart';
import 'package:flutter/material.dart';

class BackendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authentication methods
  Future<User?> signUp(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update the user's display name
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        // Also store the name in Firestore
        await _storeUserName(credential.user!.uid, name);
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('Sign up error: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected sign up error: $e');
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
    } catch (e) {
      print('Unexpected sign in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }

  // Store user name in Firestore
  Future<void> _storeUserName(String userId, String name) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': _auth.currentUser?.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error storing user name: $e');
    }
  }

  // Get user name from Firestore
  Future<String?> getUserName() async {
    if (!isAuthenticated) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .get();

      if (doc.exists) {
        return doc.data()?['name'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching user name: $e');
      return null;
    }
  }

  // Update user name in Firestore
  Future<void> updateUserName(String name) async {
    if (!isAuthenticated) return;

    try {
      await _firestore.collection('users').doc(currentUser?.uid).update({
        'name': name,
      });

      // Also update the Firebase user's display name
      if (currentUser != null) {
        await currentUser!.updateDisplayName(name);
      }
    } catch (e) {
      print('Error updating user name: $e');
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Subjects operations
  Future<void> addSubject(Subject subject) async {
    // Only proceed if user is authenticated
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('subjects')
          .doc(subject.id)
          .set(subject.toJson());
      print('Subject added to backend: ${subject.id}');
    } catch (e) {
      print('Error adding subject: $e');
    }
  }

  Future<List<Subject>> getSubjects() async {
    // Return empty list if user is not authenticated
    if (!isAuthenticated) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('subjects')
          .get();

      final subjects = snapshot.docs
          .map((doc) => Subject.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      print('Fetched ${subjects.length} subjects from backend');
      return subjects;
    } catch (e) {
      print('Error fetching subjects: $e');
      // Return empty list on error to prevent app crashes
      return [];
    }
  }

  Future<void> updateSubject(Subject subject) async {
    // Only proceed if user is authenticated
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('subjects')
          .doc(subject.id)
          .update(subject.toJson());
      print('Subject updated in backend: ${subject.id}');
    } catch (e) {
      print('Error updating subject: $e');
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    // Only proceed if user is authenticated
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('subjects')
          .doc(subjectId)
          .delete();
      print('Subject deleted from backend: $subjectId');
    } catch (e) {
      print('Error deleting subject: $e');
    }
  }

  // Attendance operations
  Future<void> addAttendanceRecord(AttendanceRecord record) async {
    // Only proceed if user is authenticated
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('attendance')
          .doc(record.id)
          .set(record.toJson());
      print('Attendance record added to backend: ${record.id}');
    } catch (e) {
      print('Error adding attendance record: $e');
    }
  }

  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    // Return empty list if user is not authenticated
    if (!isAuthenticated) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('attendance')
          .get();

      final records = snapshot.docs
          .map(
            (doc) =>
                AttendanceRecord.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();

      print('Fetched ${records.length} attendance records from backend');
      return records;
    } catch (e) {
      print('Error fetching attendance records: $e');
      // Return empty list on error to prevent app crashes
      return [];
    }
  }

  Future<void> updateAttendanceRecord(AttendanceRecord record) async {
    // Only proceed if user is authenticated
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('attendance')
          .doc(record.id)
          .update(record.toJson());
      print('Attendance record updated in backend: ${record.id}');
    } catch (e) {
      print('Error updating attendance record: $e');
    }
  }

  Future<void> deleteAttendanceRecord(String recordId) async {
    // Only proceed if user is authenticated
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('attendance')
          .doc(recordId)
          .delete();
      print('Attendance record deleted from backend: $recordId');
    } catch (e) {
      print('Error deleting attendance record: $e');
    }
  }

  // Timetable operations
  Future<void> addTimetable(Timetable timetable) async {
    // Only proceed if user is authenticated
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('timetables')
          .doc(timetable.id)
          .set(timetable.toJson());
      print('Timetable added to backend: ${timetable.id}');
    } catch (e) {
      print('Error adding timetable: $e');
    }
  }

  Future<List<Timetable>> getTimetables() async {
    // Return empty list if user is not authenticated
    if (!isAuthenticated) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('timetables')
          .get();

      final timetables = snapshot.docs
          .map((doc) => Timetable.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      print('Fetched ${timetables.length} timetables from backend');
      return timetables;
    } catch (e) {
      print('Error fetching timetables: $e');
      // Return empty list on error to prevent app crashes
      return [];
    }
  }

  Future<void> updateTimetable(Timetable timetable) async {
    // Only proceed if user is authenticated
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('timetables')
          .doc(timetable.id)
          .update(timetable.toJson());
      print('Timetable updated in backend: ${timetable.id}');
    } catch (e) {
      print('Error updating timetable: $e');
    }
  }

  Future<void> deleteTimetable(String timetableId) async {
    // Only proceed if user is authenticated
    if (!isAuthenticated) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser?.uid)
          .collection('timetables')
          .doc(timetableId)
          .delete();
      print('Timetable deleted from backend: $timetableId');
    } catch (e) {
      print('Error deleting timetable: $e');
    }
  }

  // Sync local data with backend - improved version
  Future<void> syncLocalDataWithBackend({
    required List<Subject> subjects,
    required List<AttendanceRecord> attendanceRecords,
    required List<Timetable> timetables,
  }) async {
    // Only proceed if user is authenticated
    if (!isAuthenticated) return;

    try {
      final userId = currentUser?.uid;
      if (userId == null) return;

      print(
        'Syncing ${subjects.length} subjects, ${attendanceRecords.length} attendance records, and ${timetables.length} timetables to backend',
      );

      // Instead of clearing all data, we'll sync incrementally
      // First, get existing data from backend to compare
      final existingSubjects = await getSubjects();
      final existingAttendance = await getAttendanceRecords();
      final existingTimetables = await getTimetables();

      print(
        'Existing backend data: ${existingSubjects.length} subjects, '
        '${existingAttendance.length} attendance records, '
        '${existingTimetables.length} timetables',
      );

      // Create maps for faster lookup
      final existingSubjectMap = {for (var s in existingSubjects) s.id: s};
      final existingAttendanceMap = {for (var a in existingAttendance) a.id: a};
      final existingTimetableMap = {for (var t in existingTimetables) t.id: t};

      // Sync subjects
      int subjectsAdded = 0;
      int subjectsUpdated = 0;

      for (final subject in subjects) {
        final existingSubject = existingSubjectMap[subject.id];

        if (existingSubject == null) {
          // Subject doesn't exist in backend, add it
          await addSubject(subject);
          subjectsAdded++;
        } else if (subject.toJson().toString() !=
            existingSubject.toJson().toString()) {
          // Subject exists but has changed, update it
          await updateSubject(subject);
          subjectsUpdated++;
        }
      }

      // Sync attendance records
      int attendanceAdded = 0;
      int attendanceUpdated = 0;

      for (final record in attendanceRecords) {
        final existingRecord = existingAttendanceMap[record.id];

        if (existingRecord == null) {
          // Record doesn't exist in backend, add it
          await addAttendanceRecord(record);
          attendanceAdded++;
        } else if (record.toJson().toString() !=
            existingRecord.toJson().toString()) {
          // Record exists but has changed, update it
          await updateAttendanceRecord(record);
          attendanceUpdated++;
        }
      }

      // Sync timetables
      int timetablesAdded = 0;
      int timetablesUpdated = 0;

      for (final timetable in timetables) {
        final existingTimetable = existingTimetableMap[timetable.id];

        if (existingTimetable == null) {
          // Timetable doesn't exist in backend, add it
          await addTimetable(timetable);
          timetablesAdded++;
        } else if (timetable.toJson().toString() !=
            existingTimetable.toJson().toString()) {
          // Timetable exists but has changed, update it
          await updateTimetable(timetable);
          timetablesUpdated++;
        }
      }

      print(
        'Data sync completed: '
        '$subjectsAdded subjects added, $subjectsUpdated updated; '
        '$attendanceAdded attendance records added, $attendanceUpdated updated; '
        '$timetablesAdded timetables added, $timetablesUpdated updated',
      );
    } catch (e) {
      print('Error syncing data with backend: $e');
    }
  }

  // Method to check if backend has any data for the current user
  Future<bool> hasAnyData() async {
    if (!isAuthenticated) return false;

    try {
      final userId = currentUser?.uid;
      if (userId == null) return false;

      // Check each collection for data
      final subjectsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subjects')
          .limit(1)
          .get();

      final attendanceSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('attendance')
          .limit(1)
          .get();

      final timetablesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('timetables')
          .limit(1)
          .get();

      return subjectsSnapshot.docs.isNotEmpty ||
          attendanceSnapshot.docs.isNotEmpty ||
          timetablesSnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking backend data: $e');
      return false;
    }
  }
}
