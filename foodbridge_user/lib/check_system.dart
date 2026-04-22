import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Using standard config for audit
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  
  final db = FirebaseFirestore.instance;
  print('--- SYSTEM AUDIT ---');
  
  try {
    // Check users
    final users = await db.collection('users').get();
    print('Found ${users.docs.length} users.');
    for (var u in users.docs) {
      final data = u.data();
      print('User: ${u.id} | Role: ${data['role']} | Available: ${data['isAvailable']}');
    }

    // Check requests
    final requests = await db.collection('requests').orderBy('timestamp', descending: true).limit(5).get();
    print('\n--- LATEST REQUESTS ---');
    if (requests.docs.isEmpty) {
      print('No requests found in database.');
    }
    for (var r in requests.docs) {
      final d = r.data();
      print('Req: ${r.id}');
      print('  Food: ${d['foodType']}');
      print('  Status: ${d['status']}');
      print('  AI Suggested: ${d['suggestedVolunteerId']}');
      print('  Confidence: ${d['matchConfidence']}');
    }
  } catch (e) {
    print('Database Error: $e');
  }
}
