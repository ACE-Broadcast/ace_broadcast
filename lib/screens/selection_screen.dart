import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'login_screen_admin.dart';
import 'login_screen_student.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({
    super.key,
  });

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Student Section
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreenStudent(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceDim,
                  borderRadius: BorderRadius.circular(18.0),
                  boxShadow: Theme.of(context).brightness == Brightness.light
                      ? [
                          BoxShadow(
                            blurRadius: 20,
                            color: theme.colorScheme.shadow,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Student?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SvgPicture.asset(
                            'assets/illustrations/student_illus.svg',
                            height: 200,
                          ),
                          SvgPicture.asset(
                            'assets/icons/right_arrow.svg',
                            colorFilter: ColorFilter.mode(
                                theme.colorScheme.inversePrimary,
                                BlendMode.srcIn),
                            height: 30,
                          ),
                        ]),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            //Admin Login
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceDim,
                  borderRadius: BorderRadius.circular(18.0),
                  boxShadow: Theme.of(context).brightness == Brightness.light
                      ? [
                          BoxShadow(
                            blurRadius: 20,
                            color: theme.colorScheme.shadow,
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Professor?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SvgPicture.asset(
                            'assets/illustrations/professor_illus.svg',
                            height: 200,
                          ),
                          SvgPicture.asset(
                            'assets/icons/right_arrow.svg',
                            colorFilter: ColorFilter.mode(
                                theme.colorScheme.inversePrimary,
                                BlendMode.srcIn),
                            height: 30,
                          ),
                        ]),
                  ],
                ),
              ),
            )
          ],
        ),
      )),
    );
  }
}
