import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

// Motion Detection Settings Provider
final motionDetectionEnabledProvider = StateNotifierProvider<MotionDetectionNotifier, bool>((ref) {
  return MotionDetectionNotifier();
});

class MotionDetectionNotifier extends StateNotifier<bool> {
  static const String _key = 'motion_detection_enabled';
  
  MotionDetectionNotifier() : super(true) {
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

// Motion Detection Service
class MotionDetectionService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  final void Function() onMotionDetected;
  
  // Detection parameters
  static const double _motionThreshold = 2.0; // 移動閾值
  static const int _detectionWindowSeconds = 10; // 10秒內有持續震動
  
  final List<double> _recentMagnitudes = [];
  DateTime? _lastDetectionTime;
  bool _isMonitoring = false;

  MotionDetectionService({required this.onMotionDetected});

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    _subscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _processAccelerometerData(event);
    });
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _subscription?.cancel();
    _subscription = null;
    _recentMagnitudes.clear();
  }

  void _processAccelerometerData(AccelerometerEvent event) {
    // 計算加速度大小（排除重力）
    final magnitude = sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    ) - 9.8; // 減去重力加速度
    
    _recentMagnitudes.add(magnitude.abs());
    
    // 只保留最近20個樣本（10秒）
    if (_recentMagnitudes.length > 20) {
      _recentMagnitudes.removeAt(0);
    }
    
    // 檢查是否有持續的移動
    if (_recentMagnitudes.length >= 20) {
      final avgMagnitude = _recentMagnitudes.reduce((a, b) => a + b) / _recentMagnitudes.length;
      
      // 如果平均震動超過閾值，且距離上次偵測超過5分鐘
      if (avgMagnitude > _motionThreshold) {
        final now = DateTime.now();
        if (_lastDetectionTime == null || 
            now.difference(_lastDetectionTime!).inMinutes >= 5) {
          _lastDetectionTime = now;
          onMotionDetected();
        }
      }
    }
  }

  void dispose() {
    stopMonitoring();
  }
}

// Provider for the service
final motionDetectionServiceProvider = Provider.autoDispose<MotionDetectionService?>((ref) {
  final isEnabled = ref.watch(motionDetectionEnabledProvider);
  
  if (!isEnabled) return null;
  
  // This will be initialized in the main app widget
  return null;
});
