import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'pages/task_list_screen.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/student_home_page.dart';
import 'pages/task_detail_page.dart';
import 'pages/client_profile_page.dart';
import 'pages/application_form_page.dart';
import 'pages/my_applications_page.dart';
import 'pages/client_dashboard_page.dart';
import 'pages/task_applications_page.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flex Tasks',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/tasks': (context) => const TaskListScreen(),
        '/student-home': (context) => const StudentHomePage(),
        '/my-applications': (context) => const MyApplicationsPage(),
        '/client-dashboard': (context) => const ClientDashboardPage(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in, check role and redirect
        if (snapshot.hasData && snapshot.data != null) {
          // Update online status
          _userService.updateOnlineStatus(true);

          // Check user role and redirect accordingly
          return FutureBuilder<String?>(
            future: _userService.getCurrentUserRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final role = roleSnapshot.data;

              // If role is client, show ClientDashboardPage
              if (role == 'client') {
                return const ClientDashboardPage();
              }

              // If role is student or not set, show StudentHomePage
              return const StudentHomePage();
            },
          );
        }

        // If user is not logged in, show login page
        return const LoginPage();
      },
    );
  }
}
