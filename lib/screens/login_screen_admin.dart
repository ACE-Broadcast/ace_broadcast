import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:post_ace/services/auth_service.dart';
import '../widgets/connectivity_wrapper.dart';
import 'home_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {

    void showToast(String message) {
      Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          textColor: Theme.of(context).colorScheme.onSurface,
          fontSize: 16.0);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              'WELCOME',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 120),
            Center(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Login illustration
                        SvgPicture.asset(
                          'assets/illustrations/login_prof_illus.svg',
                          height: 300,
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: 250,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final UserCredential? userCred =
                                  await _auth.loginWithGoggle();
                              if (userCred != null && context.mounted) {
                                final user = userCred.user;
                                debugPrint("User Successfully logged in");
                                showToast('Login Successful!');
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeScreen(
                                      isAdmin: true,
                                      userName: user?.displayName ?? 'User',
                                      profileUrl: user?.photoURL ?? '',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            icon: SvgPicture.asset(
                              'assets/icons/google_logo.svg',
                              height: 24,
                            ),
                            label: const Text('Sign-in with Google'),
                          ),
                        ),

                        //REMOVE THE BELOW CODE Only for testing
                        SizedBox(
                          width: 180,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ConnectivityWrapper(
                                    child: const HomeScreen(
                                      isAdmin: true,
                                      userName: 'Admin',
                                      profileUrl: '',
                                    ),
                                  ),
                                ),
                              );
                              // }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: const Text('Bypass Login'),
                          ),
                        ),
                        // Till Here
                      ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
