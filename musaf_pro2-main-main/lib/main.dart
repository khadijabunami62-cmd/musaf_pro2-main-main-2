import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'package:musaf_pro/services/notification_service.dart';

// استيراد الشاشات الأساسية
import 'package:musaf_pro/screens/splash_screen.dart';
import 'package:musaf_pro/screens/onboarding_screen.dart';
import 'package:musaf_pro/screens/patient_or_the_companion/role_selection_screen.dart';
import 'package:musaf_pro/screens/auth/login_screen.dart';
import 'package:musaf_pro/screens/auth/register_screen.dart';
import 'package:musaf_pro/screens/auth/pairing_code_screen.dart';
import 'package:musaf_pro/screens/auth/health_data_screen.dart';
import 'package:musaf_pro/screens/auth/patient_register_screen.dart';
import 'package:musaf_pro/screens/auth/caregiver_register_screen.dart';
import 'package:musaf_pro/screens/patient_home_screen.dart';
import 'package:musaf_pro/screens/caregiver_home_screen.dart';
import 'package:musaf_pro/screens/health_vitals_screen.dart';
import 'package:musaf_pro/screens/medications_screen.dart';

// 🚀 إضافة استيراد صفحة الأدوية اليومية الجديدة
import 'package:musaf_pro/screens/daily_medications_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مُسعف',
      theme: ThemeData(
        fontFamily: 'Almarai',
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const AppInitGate(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/role_selection': (context) => const RoleSelectionScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/patient_register': (context) => const PatientRegisterScreen(),
        '/caregiver_register': (context) => const CaregiverRegisterScreen(),
        '/pairing': (context) => const PairingCodeScreen(),
        '/health_data': (context) => const HealthDataScreen(),
        '/health_vitals': (context) => const HealthVitalsScreen(),
        '/medications': (context) => const MedicationsScreen(),

        // 🚀 إضافة المسار هنا يحل مشكلة الـ Error
        '/daily_medications': (context) => const DailyMedicationsListScreen(),

        '/patient_home': (context) => const PatientHomeScreen(),
        '/caregiver_home': (context) => const CaregiverHomeScreen(),
      },
    );
  }
}

// 🛡️ بوابة التحميل والتحقق (نفس كودك السابق تماماً)
class AppInitGate extends StatefulWidget {
  const AppInitGate({super.key});
  @override
  State<AppInitGate> createState() => _AppInitGateState();
}

class _AppInitGateState extends State<AppInitGate> {
  late Future<void> _initFuture;
  @override
  void initState() {
    super.initState();
    _initFuture = _initializeServices();
  }

  Future<void> _initializeServices() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const SplashScreen();
        return const AuthGate();
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const SplashScreen();
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting)
                return const SplashScreen();
              final data = userSnapshot.data?.data() as Map<String, dynamic>?;
              final String role = data?['role'] ?? 'patient';
              return role == 'caregiver'
                  ? const CaregiverHomeScreen()
                  : const PatientHomeScreen();
            },
          );
        }
        return const OnboardingScreen();
      },
    );
  }
}
