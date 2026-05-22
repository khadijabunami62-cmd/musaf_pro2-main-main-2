import 'package:flutter/material.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  final Color musafRed = const Color(0xFFB7131A);

  // مصفوفة تجريبية للمرضى المرتبطين بالمرافق (تتطابق مع قاعدة بياناتك)
  final List<Map<String, dynamic>> _patients = [
    {'name': 'أحمد سالم', 'status': 'مستقر', 'lastCheck': 'قبل ١٠ دقائق'},
    {'name': 'سارة محمد', 'status': 'تحتاج مراقبة', 'lastCheck': 'قبل ساعة'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 🚀 عهد: تم إزالة الـ AppBar والبار السفلي تماماً لتصبح الشاشة خفيفة وتابعة للهيكل
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // عنوان داخلي متناسق للشاشة
              Text(
                'قائمة المرضى تحت رعايتك',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: musafRed,
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: _patients.isEmpty
                    ? const Center(
                        child: Text('لا يوجد مرضى مرتبطين بحسابك حالياً'),
                      )
                    : ListView.builder(
                        itemCount: _patients.length,
                        itemBuilder: (context, index) {
                          final patient = _patients[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 2,
                            child: ListTile(
                              trailing: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: musafRed.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.person, color: musafRed),
                              ),
                              title: Text(
                                patient['name'],
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              subtitle: Text(
                                'الحالة: ${patient['status']} • تحديث: ${patient['lastCheck']}',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: patient['status'] == 'مستقر'
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              leading: Icon(
                                Icons.arrow_back_ios_new,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                              onTap: () {
                                debugPrint(
                                  "الضغط على المريض: ${patient['name']}",
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
