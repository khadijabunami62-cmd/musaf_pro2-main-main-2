import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

// 🚀 تم إضافة استدعاء الزر المخصص هنا
import 'package:musaf_pro/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  final Color musafRed = const Color(0xFFB7131A); // اللون الأحمر الكرزي الموحد

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // الشعار العلوي
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_box_rounded, color: musafRed, size: 30),
                  const SizedBox(width: 5),
                  Text(
                    'مُسعف',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: musafRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              const Text(
                'مرحباً بك مجدداً',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Text(
                'سجل دخولك للمتابعة في رحلة الرعاية',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // حقل الإيميل
              _buildInputLabel("رقم الجوال أو البريد الإلكتروني"),
              _buildCustomField(
                _emailController,
                "example@mail.com",
                Icons.alternate_email,
              ),

              const SizedBox(height: 20),

              // حقل كلمة المرور
              _buildInputLabel("كلمة المرور"),
              _buildCustomField(
                _passController,
                "........",
                Icons.lock_outline,
                isPass: true,
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // 🚀 التعديل هنا: استخدام الزر المخصص الموحد مع الحفاظ على دائرة التحميل
              _isLoading
                  ? CircularProgressIndicator(color: musafRed)
                  : CustomButton(
                      text: 'تسجيل الدخول',
                      isPrimary: true,
                      onPressed: _handleLogin,
                    ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/role_selection'),
                    child: Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(
                        color: musafRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Text('مستخدم جديد؟'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ الدالة الذكية لفحص الدور (Role) وتوجيه المستخدم للواجهة الصحيحة حياً ومباشراً
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال البريد وكلمة المرور')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. تسجيل الدخول الأساسي عبر الـ Auth
      var user = await _auth.signIn(
        _emailController.text.trim(),
        _passController.text.trim(),
      );

      if (user != null) {
        debugPrint("🔵 تم تسجيل الدخول بنجاح، جاري تحديد صلاحيات حسابك...");

        // 2. البحث الفوري في المستند للتحقق من الـ Role بشكل صحيح وبث ثانية
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(
              const GetOptions(source: Source.server),
            ); // سحب مباشر من السيرفر لضمان السرعة

        if (userDoc.exists && userDoc.data() != null) {
          String role = userDoc.get('role') ?? 'patient';

          // 3. التوجيه المعتمد والديناميكي بناءً على البيانات المسترجعة
          if (mounted) {
            if (role == 'caregiver') {
              debugPrint("🚀 توجيه مالي للمرافق إلى شاشة المرافق الرئيسية.");
              Navigator.pushReplacementNamed(context, '/caregiver_home');
            } else {
              debugPrint("🚀 توجيه المريض المعتاد إلى شاشة المريض الرئيسية.");
              Navigator.pushReplacementNamed(context, '/patient_home');
            }
          }
        } else {
          // حماية إضافية لو المستند غير متاح
          if (mounted) Navigator.pushReplacementNamed(context, '/patient_home');
        }
      }
    } catch (e) {
      debugPrint("🔴 خطأ أثناء تسجيل الدخول: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في البريد الإلكتروني أو كلمة المرور'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCustomField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool isPass = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPass,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
