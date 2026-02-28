// services/medication_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/medication.dart';
import 'session_manager.dart';
import 'sqflite_service.dart';
import 'package:intl/intl.dart';

class MedicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SessionManager _sessionManager = SessionManager();
  final DatabaseService _dbService = DatabaseService();

  // Get current user ID (either Firebase UID or guest ID)
  Future<String> getCurrentUserId() async {
    final session = await _sessionManager.getCurrentSession();
    if (session['type'] == SessionManager.SESSION_TYPE_REGISTERED) {
      final user = _auth.currentUser;
      if (user != null && user.emailVerified) {
        return user.uid;
      }
    } else if (session['type'] == SessionManager.SESSION_TYPE_GUEST) {
      final guestData = await _dbService.getActiveGuestSession();
      if (guestData != null) {
        return guestData['guestId'] ?? 'guest';
      }
    }
    throw Exception('No active session');
  }

  // Check if current user is guest
  Future<bool> isGuest() async {
    return await _sessionManager.isGuestMode();
  }

  // Add medication
  Future<void> addMedication(Medication medication) async {
    try {
      final isGuest = await this.isGuest();

      if (isGuest) {
        // Save to local SQLite for guests
        await _dbService.saveMedication(medication);
      } else {
        // Save to Firestore for registered users
        await _firestore
            .collection('users')
            .doc(medication.userId)
            .collection('medications')
            .doc(medication.id)
            .set(medication.toJson());
      }
    } catch (e) {
      print('Error adding medication: $e');
      rethrow;
    }
  }

  // Get all medications for current user
  Future<List<Medication>> getMedications() async {
    try {
      final isGuest = await this.isGuest();
      final userId = await getCurrentUserId();

      if (isGuest) {
        // Get from local SQLite
        return await _dbService.getMedications(userId);
      } else {
        // Get from Firestore
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('medications')
            .orderBy('createdAt', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => Medication.fromJson(doc.data()))
            .toList();
      }
    } catch (e) {
      print('Error getting medications: $e');
      return [];
    }
  }

  // Get single medication by ID
  Future<Medication?> getMedicationById(String medicationId) async {
    try {
      final isGuest = await this.isGuest();
      final userId = await getCurrentUserId();

      if (isGuest) {
        return await _dbService.getMedicationById(userId, medicationId);
      } else {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('medications')
            .doc(medicationId)
            .get();

        if (doc.exists) {
          return Medication.fromJson(doc.data()!);
        }
        return null;
      }
    } catch (e) {
      print('Error getting medication by ID: $e');
      return null;
    }
  }

  // Update medication
  Future<void> updateMedication(Medication medication) async {
    try {
      final isGuest = await this.isGuest();

      if (isGuest) {
        await _dbService.updateMedication(medication);
      } else {
        await _firestore
            .collection('users')
            .doc(medication.userId)
            .collection('medications')
            .doc(medication.id)
            .update(medication.toJson());
      }
    } catch (e) {
      print('Error updating medication: $e');
      rethrow;
    }
  }

  // Delete medication
  Future<void> deleteMedication(String medicationId) async {
    try {
      final isGuest = await this.isGuest();
      final userId = await getCurrentUserId();

      if (isGuest) {
        await _dbService.deleteMedication(userId, medicationId);
      } else {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('medications')
            .doc(medicationId)
            .delete();
      }
    } catch (e) {
      print('Error deleting medication: $e');
      rethrow;
    }
  }

  // 🔴 ADD THIS METHOD - Mark medication as taken
  Future<void> markAsTaken(String medicationId) async {
    try {
      final isGuest = await this.isGuest();
      final userId = await getCurrentUserId();
      final takenAt = DateTime.now();

      if (isGuest) {
        await _dbService.markMedicationAsTaken(userId, medicationId, takenAt);
      } else {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('medications')
            .doc(medicationId)
            .update({'isTaken': true, 'takenAt': takenAt.toIso8601String()});
      }

      // Show notification that medication was taken
      print('Medication $medicationId marked as taken at $takenAt');
    } catch (e) {
      print('Error marking medication as taken: $e');
      rethrow;
    }
  }

  // Get active medications only
  Future<List<Medication>> getActiveMedications() async {
    try {
      final isGuest = await this.isGuest();
      final userId = await getCurrentUserId();

      if (isGuest) {
        return await _dbService.getActiveMedications(userId);
      } else {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('medications')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => Medication.fromJson(doc.data()))
            .toList();
      }
    } catch (e) {
      print('Error getting active medications: $e');
      return [];
    }
  }

  // Toggle medication active status
  Future<void> toggleMedicationStatus(
    String medicationId,
    bool isActive,
  ) async {
    try {
      final isGuest = await this.isGuest();
      final userId = await getCurrentUserId();

      if (isGuest) {
        await _dbService.toggleMedicationStatus(userId, medicationId, isActive);
      } else {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('medications')
            .doc(medicationId)
            .update({'isActive': isActive});
      }
    } catch (e) {
      print('Error toggling medication status: $e');
      rethrow;
    }
  }

  // Update medication image
  Future<void> updateMedicationImage(
    String medicationId,
    String imagePath,
  ) async {
    try {
      final isGuest = await this.isGuest();
      final userId = await getCurrentUserId();

      if (isGuest) {
        await _dbService.updateMedicationImage(userId, medicationId, imagePath);
      } else {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('medications')
            .doc(medicationId)
            .update({'imagePath': imagePath});
      }
    } catch (e) {
      print('Error updating medication image: $e');
      rethrow;
    }
  }

  // Search medications
  Future<List<Medication>> searchMedications(String searchTerm) async {
    try {
      final isGuest = await this.isGuest();
      final userId = await getCurrentUserId();

      if (isGuest) {
        return await _dbService.searchMedications(userId, searchTerm);
      } else {
        // Firestore doesn't support native text search, so we'll do client-side filtering
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('medications')
            .orderBy('createdAt', descending: true)
            .get();

        return snapshot.docs
            .map((doc) => Medication.fromJson(doc.data()))
            .where(
              (med) =>
                  med.name.toLowerCase().contains(searchTerm.toLowerCase()),
            )
            .toList();
      }
    } catch (e) {
      print('Error searching medications: $e');
      return [];
    }
  }

  // Get medications count for debugging
  Future<int> getMedicationsCount() async {
    try {
      final isGuest = await this.isGuest();
      if (isGuest) {
        final userId = await getCurrentUserId();
        return await _dbService.getMedicationsCount(userId);
      } else {
        final userId = await getCurrentUserId();
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('medications')
            .get();
        return snapshot.docs.length;
      }
    } catch (e) {
      print('Error getting medications count: $e');
      return 0;
    }
  }

  // Stream medications (for real-time updates)
  Stream<List<Medication>> streamMedications() async* {
    try {
      final isGuest = await this.isGuest();
      final userId = await getCurrentUserId();

      if (isGuest) {
        // For guests, we can't have real-time stream from SQLite easily
        // So we'll yield periodically or when notified
        yield await _dbService.getMedications(userId);
      } else {
        yield* _firestore
            .collection('users')
            .doc(userId)
            .collection('medications')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => Medication.fromJson(doc.data()))
                  .toList(),
            );
      }
    } catch (e) {
      print('Error streaming medications: $e');
      yield [];
    }
  }

  // Get medications that are still active (course not completed)
  Future<List<Medication>> getActiveCourses() async {
    try {
      final allMeds = await getMedications();
      final now = DateTime.now();

      return allMeds.where((med) {
        if (!med.isActive) return false;
        final endDate = med.createdAt.add(Duration(days: med.numberOfDays));
        return endDate.isAfter(now);
      }).toList();
    } catch (e) {
      print('Error getting active courses: $e');
      return [];
    }
  }

  // Get completed medications
  Future<List<Medication>> getCompletedMedications() async {
    try {
      final allMeds = await getMedications();
      final now = DateTime.now();

      return allMeds.where((med) {
        if (!med.isActive) return true;
        final endDate = med.createdAt.add(Duration(days: med.numberOfDays));
        return endDate.isBefore(now);
      }).toList();
    } catch (e) {
      print('Error getting completed medications: $e');
      return [];
    }
  }

  // Add these methods to medication_service.dart

  // Record medication as taken (for history)
  Future<void> recordMedicationTaken(String medicationId) async {
    try {
      final isGuest = await this.isGuest();
      final userId = await getCurrentUserId();
      final takenAt = DateTime.now();

      if (isGuest) {
        await _dbService.recordMedicationTaken(userId, medicationId, takenAt);
      } else {
        // Store in Firestore under history subcollection
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('medication_history')
            .add({
              'medicationId': medicationId,
              'takenAt': takenAt.toIso8601String(),
              'date': DateFormat('yyyy-MM-dd').format(takenAt),
            });
      }
    } catch (e) {
      print('Error recording medication taken: $e');
    }
  }

  // Get today's medications that are due
  Future<List<Medication>> getTodaysMedications() async {
    try {
      final allMeds = await getMedications();
      final now = DateTime.now();

      return allMeds.where((med) {
        if (!med.isActive) return false;
        final endDate = med.createdAt.add(Duration(days: med.numberOfDays));
        return !endDate.isBefore(DateTime(now.year, now.month, now.day));
      }).toList();
    } catch (e) {
      print('Error getting today\'s medications: $e');
      return [];
    }
  }
}
