import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lottie/lottie.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onConnectionRestored;

  const ConnectivityWrapper({
    Key? key,
    required this.child,
    this.onConnectionRestored,
  }) : super(key: key);

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isConnected = true;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();

    // Listen for connectivity changes
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final wasConnected = _isConnected;
      setState(() {
        // Update connection status based on results
        _isConnected = results.isNotEmpty &&
            results.any((result) => result != ConnectivityResult.none);
      });

      // If connection was restored and callback exists, call it
      if (!wasConnected &&
          _isConnected &&
          widget.onConnectionRestored != null) {
        widget.onConnectionRestored!();
      }
    });
  }

  @override
  void dispose() {
    // Cancel the subscription to avoid memory leaks
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return widget.child;
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottie/no_internet.json',
              height: 350,
              width: 350,
            ),
            const Text(
              'No Internet Connection!',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Fetch the current connectivity status
                final List<ConnectivityResult> connectivityResults =
                    await Connectivity().checkConnectivity();

                // Check if there's no connection
                setState(() {
                  _isConnected = connectivityResults.isNotEmpty &&
                      connectivityResults
                          .any((result) => result != ConnectivityResult.none);
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Retry'),
            )
          ],
        ),
      ),
    );
  }
}
