import 'package:flutter_monitor_sdk/src/core/monitor_binding.dart';
import 'package:flutter_monitor_sdk/src/core/monitor_config.dart';
import 'package:flutter_monitor_sdk/src/utils/monitored_gesture_detector.dart';

// 重新导出配置类和监控Widget，方便使用者导入
export 'package:flutter_monitor_sdk/src/core/monitor_config.dart';
export 'package:flutter_monitor_sdk/src/utils/monitored_gesture_detector.dart';
export 'package:flutter_monitor_sdk/src/modules/performance_monitor.dart' show MonitorDioInterceptor;


class FlutterMonitorSDK {
  FlutterMonitorSDK._();

  static final FlutterMonitorSDK _instance = FlutterMonitorSDK._();
  static FlutterMonitorSDK get instance => _instance;

  static bool _isInitialized = false;

  static Future<void> init({
    required MonitorConfig config,
    required DateTime appStartTime,
  }) async {
    if (_isInitialized) {
      print("FlutterMonitorSDK has already been initialized.");
      return;
    }

    MonitorBinding.init(config: config, appStartTime: appStartTime);
    _isInitialized = true;
    print("FlutterMonitorSDK initialized successfully.");
  }

  void setUserId(String userId) {
    if (!_isInitialized) return;
    MonitorBinding.instance.config.userId = userId;
  }

  void setCustomData(Map<String, dynamic> data) {
    if (!_isInitialized) return;
    MonitorBinding.instance.config.customData = data;
  }

  void reportEvent(String eventType, Map<String, dynamic> data) {
    if (!_isInitialized) return;
    MonitorBinding.instance.reporter.addEvent(eventType, data);
  }
}
