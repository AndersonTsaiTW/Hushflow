import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/motion_detection_provider.dart';

/// Wrapper widget that monitors motion and shows dialog when detected
class MotionDetectionWrapper extends ConsumerStatefulWidget {
  final Widget child;
  
  const MotionDetectionWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MotionDetectionWrapper> createState() => _MotionDetectionWrapperState();
}

class _MotionDetectionWrapperState extends ConsumerState<MotionDetectionWrapper> {
  MotionDetectionService? _service;
  bool _dialogShown = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  void _initializeService(bool isEnabled) {
    if (isEnabled && _service == null) {
      _service = MotionDetectionService(
        onMotionDetected: _showMotionDialog,
      );
      _service?.startMonitoring();
    } else if (!isEnabled && _service != null) {
      _service?.dispose();
      _service = null;
    }
  }

  void _showMotionDialog() {
    // Prevent showing multiple dialogs
    if (_dialogShown || !mounted) return;
    _dialogShown = true;

    // Use post frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.directions_car, size: 48),
          title: const Text('Motion Detected'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Looks like you\'re on the move!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Would you like to listen to your latest summary?',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _dialogShown = false;
              },
              child: const Text('Not Now'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _dialogShown = false;
                _playAudioSummary();
              },
              icon: const Icon(Icons.headphones),
              label: const Text('Play Summary'),
            ),
          ],
        ),
      ).then((_) {
        // Reset dialog shown flag after dialog is dismissed
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _dialogShown = false;
          }
        });
      });
    });
  }

  void _playAudioSummary() {
    if (!mounted) return;
    
    // TODO: Implement actual audio playback
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.play_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Playing audio summary... (Demo mode)'),
            ),
          ],
        ),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _service?.dispose();
    _service = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch for provider changes
    final isEnabled = ref.watch(motionDetectionEnabledProvider);
    
    // Initialize or update service based on enabled state
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeService(isEnabled);
      });
    } else {
      // Handle toggle changes
      if (isEnabled && _service == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeService(true);
        });
      } else if (!isEnabled && _service != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeService(false);
        });
      }
    }
    
    return widget.child;
  }
}
