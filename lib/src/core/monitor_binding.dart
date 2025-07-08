import 'package:flutter/material.dart';
import 'package:flutter_monitor_sdk/src/core/monitor_config.dart';
import 'package:flutter_monitor_sdk/src/core/reporter.dart';
import 'package:flutter_monitor_sdk/src/modules/behavior_monitor.dart';
import 'package:flutter_monitor_sdk/src/modules/error_monitor.dart';
import 'package:flutter_monitor_sdk/src/modules/performance_monitor.dart';

/// A singleton binding that glues all the monitoring services together.
/// It's the internal core of the SDK.
class MonitorBinding {
  // --- Singleton Setup ---

  /// Private constructor to ensure it's only created internally.
  MonitorBinding._(this.config, {required DateTime appStartTime}) {
    // 1. Initialize the reporter first, as other modules depend on it.
    reporter = Reporter(config);

    // 2. Initialize individual monitoring modules if they are enabled in the config.
    if (config.enableErrorMonitor) {
      errorMonitor = ErrorMonitor(reporter);
      errorMonitor.init();
    }

    if (config.enablePerformanceMonitor) {
      performanceMonitor = PerformanceMonitor(reporter);
      // Pass the app start time to the performance monitor for launch time calculation.
      performanceMonitor.init(appStartTime);
    }

    if (config.enableBehaviorMonitor) {
      behaviorMonitor = BehaviorMonitor(reporter);
      // Behavior monitor might also have an init for things like lifecycle listeners
      behaviorMonitor.init();
    }
  }

  /// The single, static instance of the binding.
  static MonitorBinding? _instance;

  /// Public accessor for the singleton instance.
  /// Throws an assertion error if accessed before initialization.
  static MonitorBinding get instance {
    assert(_instance != null,
      'MonitorBinding has not been initialized. Call FlutterMonitorSDK.init() first.');
    return _instance!;
  }

  // --- Initialization Method ---

  /// This is the main entry point for creating and setting up the binding.
  /// It's called by the public-facing `FlutterMonitorSDK.init()`.
  static void init({required MonitorConfig config, required DateTime appStartTime}) {
    if (_instance != null) {
      print("Warning: MonitorBinding has already been initialized.");
      return;
    }
    _instance = MonitorBinding._(config, appStartTime: appStartTime);
  }

  // --- Publicly Accessible Services ---

  /// The configuration for the SDK.
  final MonitorConfig config;

  /// The reporter service for sending data.
  late final Reporter reporter;

  /// The error monitoring service.
  late final ErrorMonitor errorMonitor;

  /// The performance monitoring service.
  late final PerformanceMonitor performanceMonitor;

  /// The behavior monitoring service.
  late final BehaviorMonitor behaviorMonitor;

  /// A method to dispose resources when the app is closing, if necessary.
  void dispose() {
    reporter.dispose();
  }
}
