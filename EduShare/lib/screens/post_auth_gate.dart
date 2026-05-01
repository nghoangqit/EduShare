import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import 'app_shell.dart';
import 'complete_profile_screen.dart';
import 'login_screen.dart';

class PostAuthGate extends StatefulWidget {
  const PostAuthGate({super.key});

  @override
  State<PostAuthGate> createState() => _PostAuthGateState();
}

class _PostAuthGateState extends State<PostAuthGate> {
  final FirebaseDataService _dataService = FirebaseDataService.instance;
  late Future<UserProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _dataService.getCurrentUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _profileFuture.timeout(const Duration(seconds: 10)),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.red),
                    const SizedBox(height: 12),
                    const Text(
                      'Khong tai duoc ho so nguoi dung.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kiem tra mang hoac dang nhap lai.',
                      style: TextStyle(color: AppColors.textGray),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await context.read<AuthProvider>().logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Dang nhap lai'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final profile = snapshot.data;
        if (profile == null) {
          return const LoginScreen();
        }

        if (profile.isIncomplete) {
          return CompleteProfileScreen(
            profile: profile,
            onCompleted: () {
              setState(() {
                _profileFuture = _dataService.getCurrentUserProfile();
              });
            },
          );
        }

        return const AppShell();
      },
    );
  }
}
