import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  final Color primaryRed = const Color(0xFFB7131A); // اللون الموحد لتطبيق مُسعف
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "لوحة تحكم المرافق",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/role_selection');
              }
            },
          ),
        ],
      ),
      body: currentUserId == null
          ? const Center(child: Text("يرجى تسجيل الدخول"))
          : _buildCaregiverDashboard(),
    );
  }

  // 1. جلب بيانات المرافق لمعرفة ID المريض المرتبط به
  Widget _buildCaregiverDashboard() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, caregiverSnapshot) {
        if (caregiverSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryRed));
        }
        if (!caregiverSnapshot.hasData || !caregiverSnapshot.data!.exists) {
          return const Center(child: Text("بيانات المرافق غير موجودة"));
        }

        var caregiverData =
            caregiverSnapshot.data!.data() as Map<String, dynamic>;
        String? linkedPatientId = caregiverData['linkedPatientId'];

        if (linkedPatientId == null || linkedPatientId.isEmpty) {
          return Center(
            child: Text(
              "لم يتم ربطك بأي مريض حتى الآن.",
              style: TextStyle(fontSize: 18, color: primaryRed),
            ),
          );
        }

        // 2. إذا كان مرتبط بمريض، نجيب بيانات المريض والتنبيهات
        return _buildPatientInfoAndAlerts(linkedPatientId);
      },
    );
  }

  // 3. بناء واجهة المريض وعرض التنبيهات الخاصة به
  Widget _buildPatientInfoAndAlerts(String patientId) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            "المريض التابع لك",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          // --- بطاقة المريض الحقيقي ---
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(patientId)
                .snapshots(),
            builder: (context, patientSnapshot) {
              if (!patientSnapshot.hasData) return const SizedBox();

              var patientData =
                  patientSnapshot.data?.data() as Map<String, dynamic>?;
              String patientName =
                  patientData?['displayName'] ?? 'مريض غير معروف';
              String patientPhone =
                  patientData?['phoneNumber'] ?? 'لا يوجد رقم';

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  leading: CircleAvatar(
                    backgroundColor: primaryRed.withOpacity(0.1),
                    radius: 25,
                    child: Icon(Icons.person, color: primaryRed, size: 30),
                  ),
                  title: Text(
                    "المريض: $patientName",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    "رقم الجوال: $patientPhone\nحالة الالتزام: قيد المتابعة",
                  ),
                  trailing: Icon(
                    Icons.monitor_heart_outlined,
                    color: primaryRed,
                    size: 30,
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),

          const SizedBox(height: 30),
          const Text(
            "تنبيهات الطوارئ (SOS) 🚨",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 10),

          // --- جلب التنبيهات الحية من جدول family_alerts ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('family_alerts')
                  .where(
                    'patientId',
                    isEqualTo: patientId,
                  ) // نجيب تنبيهات هذا المريض بس
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, alertsSnapshot) {
                if (alertsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!alertsSnapshot.hasData ||
                    alertsSnapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "لا توجد تنبيهات طوارئ حالياً. مريضك بخير ولله الحمد! 💚",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: alertsSnapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var alertDoc = alertsSnapshot.data!.docs[index];
                    var alertData = alertDoc.data() as Map<String, dynamic>;
                    String message = alertData['message'] ?? 'تنبيه طارئ!';
                    bool isUnread = alertData['status'] == 'unread';

                    return Card(
                      color: isUnread ? Colors.red.shade50 : Colors.white,
                      elevation: isUnread ? 2 : 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isUnread
                              ? Colors.red.shade300
                              : Colors.grey.shade200,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 35,
                        ),
                        title: Text(
                          message,
                          style: TextStyle(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: Colors.red.shade900,
                          ),
                        ),
                        subtitle: const Text(
                          "اضغط لتأكيد استلام التنبيه",
                          style: TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          // تحويل حالة التنبيه إلى مقروء عند الضغط عليه
                          FirebaseFirestore.instance
                              .collection('family_alerts')
                              .doc(alertDoc.id)
                              .update({'status': 'read'});
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
