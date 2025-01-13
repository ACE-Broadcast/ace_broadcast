import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lottie/lottie.dart';
import 'package:post_ace/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onConnectionRestored;
  final Future<bool> Function()? checkForCachedData;
  final VoidCallback? loadCachedData;

  const ConnectivityWrapper({
    Key? key,
    required this.child,
    this.onConnectionRestored,
    this.checkForCachedData,
    this.loadCachedData,
  }) : super(key: key);

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isConnected = true;
  bool _showNoInternetScreen = false;
  bool _hasCachedData = false;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Check if we have cached data
    if (widget.checkForCachedData != null) {
      _hasCachedData = await widget.checkForCachedData!();
      debugPrint('_hasCachedData is false');
    }

    // Load cached posts if cached data exists
    if (_hasCachedData && widget.loadCachedData != null) {
      widget.loadCachedData!();
    }

    // Then check connectivity
    await _checkInitialConnectivity();
    _setupConnectivityListener();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final hasConnection = results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);

    if (mounted) {
      setState(() {
        _isConnected = hasConnection;
        _showNoInternetScreen = !hasConnection && !_hasCachedData;
      });
    }
  }

  void _setupConnectivityListener() {
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final wasConnected = _isConnected;
      final hasConnection = results.isNotEmpty &&
          results.any((result) => result != ConnectivityResult.none);

      if (mounted) {
        setState(() {
          _isConnected = hasConnection;
          _showNoInternetScreen = !hasConnection && !_hasCachedData;
        });
      }

      // If connection was restored and callback exists, call it
      if (!wasConnected &&
          hasConnection &&
          widget.onConnectionRestored != null) {
        widget.onConnectionRestored!();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showNoInternetScreen) {
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
                  await _checkInitialConnectivity();
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

    return Stack(
      children: [
        widget.child,
        if (!_isConnected)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 20,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Check your internet connection',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
