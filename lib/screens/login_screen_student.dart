import 'package:flutter/material.dart';
import '../widgets/connectivity_wrapper.dart';
import 'home_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:post_ace/services/auth_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreenStudent extends StatefulWidget {
  const LoginScreenStudent({super.key});

  @override
  State<LoginScreenStudent> createState() => _LoginScreenStudentState();
}

class _LoginScreenStudentState extends State<LoginScreenStudent> {
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
        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          const SizedBox(height: 40),
          const Text(
            'WELCOME',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(
            height: 100,
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/illustrations/login_student_illus.svg',
                      height: 250,
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                      width: 250,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final UserCredential? userCred =
                                await _auth.loginWithGoggle();
                            if (userCred != null && context.mounted) {
                              final User? user = userCred.user;
                              final String? email = user?.email;

                              if (email != null &&
                                  email.endsWith('@atharvacoe.ac.in')) {
                                showToast('Login Successful!');
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomeScreen(
                                      isAdmin: false,
                                      userName: user?.displayName ?? 'Student',
                                      profileUrl: user?.photoURL ?? '',
                                    ),
                                  ),
                                );
                              } else {
                                showToast(
                                    'Please use your college email address');
                              }
                            }
                          } catch (e) {
                            showToast("Error during Google Sign In: $e");
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
                    const SizedBox(height: 26),

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
                                  isAdmin: false,
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
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
