import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../services/auth_service.dart';
import '../../services/email_service.dart';

// 🚀 تم إضافة استدعاء الزر المخصص الموحد هنا
import 'package:musaf_pro/widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();

  // الحقول الأساسية
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // حقول المريض فقط
  final _caregiverEmailController = TextEditingController();
  String? _selectedRelation;

  bool _isLoading = false;
  final Color primaryRed = const Color(0xFFB7131A);
  String? userRole;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // استقبال الدور المختار من الصفحة السابقة
    userRole = ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          userRole == 'patient' ? 'تسجيل مريض' : 'تسجيل مرافق',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildFieldLabel("الاسم الكامل", Icons.person_outline),
            _buildCustomTextField(_nameController, "الاسم الثلاثي"),

            const SizedBox(height: 15),
            _buildFieldLabel("رقم الجوال", Icons.phone_android_outlined),
            _buildCustomTextField(
              _phoneController,
              "+966 5X XXX XXXX",
              isNumber: true,
            ),

            const SizedBox(height: 15),
            _buildFieldLabel("البريد الإلكتروني", Icons.email_outlined),
            _buildCustomTextField(_emailController, "example@mail.com"),

            // --- تظهر هذه الحقول فقط إذا كان المستخدم مريضاً ---
            if (userRole == 'patient') ...[
              const SizedBox(height: 15),
              _buildFieldLabel(
                "بريد المرافق (لإرسال الكود)",
                Icons.alternate_email_rounded,
              ),
              _buildCustomTextField(
                _caregiverEmailController,
                "caregiver@mail.com",
              ),
              const SizedBox(height: 15),
              _buildFieldLabel("صلة القرابة للمرافق", Icons.people_outline),
              _buildDropdownField(),
            ],

            const SizedBox(height: 15),
            _buildFieldLabel("كلمة المرور", Icons.lock_outline),
            _buildCustomTextField(_passController, "........", isPass: true),

            const SizedBox(height: 15),
            _buildFieldLabel("تأكيد كلمة المرور", Icons.lock_reset_outlined),
            _buildCustomTextField(
              _confirmPassController,
              "........",
              isPass: true,
            ),

            const SizedBox(height: 40),

            // 🚀 التعديل الوحيد هنا: استخدام الزر المخصص مع الحفاظ على المنطق
            _isLoading
                ? CircularProgressIndicator(color: primaryRed)
                : CustomButton(
                    text: userRole == 'patient'
                        ? 'إنشاء حساب ومتابعة'
                        : 'إنشاء حساب مرافق',
                    isPrimary: true, // زر أساسي أحمر
                    onPressed: _handleRegister,
                  ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ✅ دالة التسجيل مع التتبع (لصيد التعليق) وإجبار الاتصال بالسيرفر (بدون أي مساس)
  void _handleRegister() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      _showError('يرجى ملء البيانات الأساسية');
      return;
    }

    if (userRole == 'patient' && _caregiverEmailController.text.isEmpty) {
      _showError('يرجى إدخال بريد المرافق لإرسال كود الربط');
      return;
    }

    if (_passController.text != _confirmPassController.text) {
      _showError('كلمات المرور غير متطابقة');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String enteredEmail = _emailController.text.trim();
      String? linkedPatientId;

      debugPrint("🔵 الخطوة 1: بدأنا التسجيل بدور: $userRole");

      // 🚀 1. درع الحماية والبحث الذكي للمرافق
      if (userRole == 'caregiver') {
        debugPrint("🔵 الخطوة 2: جاري البحث عن المريض بالسيرفر مباشرة...");

        // إجبار الفايربيس على البحث في السيرفر لمنع التعليق
        var patientQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('caregiverEmail', isEqualTo: enteredEmail)
            .get(const GetOptions(source: Source.server));

        debugPrint(
          "🔵 الخطوة 3: انتهى البحث. عدد المرضى اللي لقيتهم: ${patientQuery.docs.length}",
        );

        if (patientQuery.docs.isEmpty) {
          _showError('❌ هذا البريد غير مصرح له! يجب أن يضيفك المريض أولاً.');
          setState(() => _isLoading = false);
          return;
        } else {
          linkedPatientId = patientQuery.docs.first.id;
          debugPrint(
            "🔵 الخطوة 4: تم إيجاد المريض بنجاح! ID المريض: $linkedPatientId",
          );
        }
      }

      debugPrint("🔵 الخطوة 5: جاري التواصل مع Firebase Auth لإنشاء الحساب...");

      var user = await _auth.registerUser(
        enteredEmail,
        _passController.text.trim(),
        userRole!,
      );

      if (user == null) {
        debugPrint("🔴 الخطوة 6: فشل إنشاء الحساب في Auth!");
        setState(() => _isLoading = false);
        return;
      }

      debugPrint(
        "🔵 الخطوة 6: تم إنشاء الحساب! جاري حفظ البيانات بـ Firestore...",
      );

      Map<String, dynamic> userData = {
        'uid': user.uid,
        'displayName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'role': userRole,
        'email': enteredEmail,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (userRole == 'patient') {
        String generatedCode = (Random().nextInt(9000) + 1000).toString();
        userData['caregiverEmail'] = _caregiverEmailController.text.trim();
        userData['relation'] = _selectedRelation;
        userData['pairingCode'] = generatedCode;
        userData['isCaregiverVerified'] = false;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);
        debugPrint("🔵 الخطوة 7: تم حفظ المريض بنجاح.");

        await EmailService.sendPairingCode(
          toEmail: _caregiverEmailController.text.trim(),
          pairingCode: generatedCode,
        );

        if (mounted) Navigator.pushReplacementNamed(context, '/pairing');
      } else if (userRole == 'caregiver') {
        userData['linkedPatientId'] = linkedPatientId;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(userData);
        debugPrint(
          "🔵 الخطوة 7: تم حفظ المرافق وربطه بنجاح! جاري التوجيه للوحة التحكم...",
        );

        if (mounted) Navigator.pushReplacementNamed(context, '/caregiver_home');
      }
    } catch (e) {
      debugPrint("🔴 خطأ برمجي صادم: $e");
      _showError('تنبيه: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- الأدوات المساعدة للواجهة ---
  Widget _buildFieldLabel(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 18, color: Colors.grey[600]),
        ],
      ),
    );
  }

  Widget _buildCustomTextField(
    TextEditingController ctrl,
    String hint, {
    bool isPass = false,
    bool isNumber = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPass,
        textAlign: TextAlign.right,
        keyboardType: isNumber
            ? TextInputType.phone
            : TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRelation,
          isExpanded: true,
          hint: const Text('اختر صلة القرابة', textAlign: TextAlign.right),
          items: [
            'أب/أم',
            'ابن/ابنة',
            'أخ/أخت',
            'زوج/زوجة',
            'أخرى',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) => setState(() => _selectedRelation = val),
        ),
      ),
    );
  }
}
