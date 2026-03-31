import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/job_description_model.dart';

class JobDescriptionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  JobDescriptionService();

  /// Upload multiple files to Firebase Storage directly.
  /// Returns a list of download URLs.
  Future<List<String>> uploadFiles({
    required List<File> files,
    required String projectId,
    String? token, // Token is actually not needed for Firebase SDK if signed in
  }) async {
    final List<String> uploadedUrls = [];

    for (final file in files) {
      try {
        final fileName = file.path.split(Platform.pathSeparator).last;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ref = _storage.ref().child('projects/$projectId/job_desc/${timestamp}_$fileName');
        
        final uploadTask = await ref.putFile(file);
        final url = await uploadTask.ref.getDownloadURL();
        uploadedUrls.add(url);
      } catch (e) {
        if (kDebugMode) print('File upload error: $e');
      }
    }

    return uploadedUrls;
  }

  /// Create a job description with metadata and file URLs in Firestore.
  Future<JobDescription> createJobDescription({
    required String projectId,
    required String title,
    required String description,
    required List<String> fileUrls,
    String? token,
  }) async {
    try {
      final docRef = _db.collection('job_desc').doc(projectId);
      final jobDesc = JobDescription(
        projectId: projectId,
        title: title,
        description: description,
        fileUrls: fileUrls,
        createdAt: DateTime.now(),
      );

      await docRef.set(jobDesc.toJson());
      return jobDesc;
    } catch (e) {
      if (kDebugMode) {
        print('JobDescriptionService.createJobDescription error: $e');
      }
      rethrow;
    }
  }

  /// Fetch job description for a specific project from Firestore.
  Future<JobDescription?> fetchJobDescription({
    required String projectId,
    String? token,
  }) async {
    try {
      final doc = await _db.collection('job_desc').doc(projectId).get();

      if (doc.exists && doc.data() != null) {
        return JobDescription.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('JobDescriptionService.fetchJobDescription error: $e');
      }
      return null;
    }
  }
}
