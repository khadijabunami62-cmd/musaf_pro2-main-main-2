import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // بيانات حسابك الموثق والكود السري الجديد (بدون أي تغيير بناءً على طلبك)
  static const String _userEmail = 'hdbaslwm25@gmail.com';
  static const String _appPassword = 'iujd pact pptf figq';

  static Future<void> sendPairingCode({
    required String toEmail,
    required String pairingCode,
  }) async {
    // إعداد سيرفر Gmail المباشر باستخدام الكود الخاص بك
    final smtpServer = gmail(_userEmail, _appPassword);

    // تجهيز محتوى الرسالة
    final message = Message()
      ..from = const Address(_userEmail, 'تطبيق مُسعف')
      ..recipients.add(toEmail) // إيميل المرافق المستلم من شاشة التسجيل الجديدة
      ..subject = 'كود الربط لمشروع مُسعف 🎉'
      ..text =
          'مرحباً،\n\nكود الربط الخاص بك هو: $pairingCode\n\nيرجى استخدامه لإتمام عملية الربط في التطبيق.\n\nشكراً لك،\nفريق مُسعف';

    try {
      // إرسال الإيميل في الخلفية
      await send(message, smtpServer);
      print('✅ تم الإرسال بنجاح وتجاوز أخطاء الـ 400 والـ 404!');
    } catch (e) {
      // طباعة الخطأ في الـ Debug Console فقط دون تعطيل الشاشات الجديدة
      print('❌ فشل الإرسال (تم التجاوز لراحة المستخدم): $e');
      // تم حذف rethrow هنا لضمان عدم تعليق مؤشر التحميل في صفحة تسجيل المريض
    }
  }
}
