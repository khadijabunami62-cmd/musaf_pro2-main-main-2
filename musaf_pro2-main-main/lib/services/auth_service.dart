import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. دالة تسجيل الدخول (التي كانت ناقصة وتسبب الإيرور)
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      debugPrint("خطأ في تسجيل الدخول: ${e.toString()}");
      return null;
    }
  }

  // 2. دالة تسجيل مريض أو مرافق (التي كتبتيها يا عهد)
  Future<User?> registerUser(
    String email,
    String password,
    String userType,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // توليد كود الربط المكون من 6 أرقام
        String pCode = (Random().nextInt(900000) + 100000).toString();

        // تخزين البيانات في جدول موحد اسمه users
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'userType': userType, // مريض أو مرافق
          'pairingCode': pCode,
          'linkedTo': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      debugPrint("خطأ في التسجيل: ${e.toString()}");
      return null;
    }
  }

  // دالة تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
