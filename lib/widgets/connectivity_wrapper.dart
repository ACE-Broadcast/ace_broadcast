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
  final Future<void> Function()? loadCachedData;

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
  bool _isInitialLoad = true;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (widget.checkForCachedData != null) {
      _hasCachedData = await widget.checkForCachedData!();
      if (_hasCachedData && widget.loadCachedData != null) {
        widget.loadCachedData!();
      }
    }

    final results = await Connectivity().checkConnectivity();
    final hasConnection =
        results.any((result) => result != ConnectivityResult.none);

    if (mounted) {
      setState(() {
        _isConnected = hasConnection;
        _showNoInternetScreen =
            _isInitialLoad && !hasConnection && !_hasCachedData;
        _isInitialLoad = false;
      });
    }

    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final wasConnected = _isConnected;
      final hasConnection =
          results.any((result) => result != ConnectivityResult.none);

      if (mounted) {
        setState(() {
          _isConnected = hasConnection;
          _showNoInternetScreen = false;
        });

        if (!hasConnection && _hasCachedData && widget.loadCachedData != null) {
          widget.loadCachedData!();
        }

        if (!wasConnected &&
            hasConnection &&
            widget.onConnectionRestored != null) {
          widget.onConnectionRestored!();
        }
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
                  await _initialize();
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
    return widget.child;
  }
}
