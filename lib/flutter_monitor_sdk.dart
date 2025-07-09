import 'package:flutter_monitor_sdk/src/utIls/monitored_http_client.dart';
import 'package:flutter_monitor_sdk/src/utils/monitored_gesture_detector.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'flutter_monitor_sdk.dart';

export 'package:flutter_monitor_sdk/src/core/monitor_binding.dart';
export 'package:flutter_monitor_sdk/src/core/monitor_config.dart';
export 'package:flutter_monitor_sdk/src/modules/performance_monitor.dart';
export 'package:flutter_monitor_sdk/src/utils/monitored_gesture_detector.dart';




class FlutterMonitorSDK {
  FlutterMonitorSDK._();

  static final FlutterMonitorSDK _instance = FlutterMonitorSDK._();
  static FlutterMonitorSDK get instance => _instance;

  static bool _isInitialized = false;

  static RouteObserver get routeObserver {
    assert(_isInitialized, '请先调用 FlutterMonitorSDK.init() 再使用 routeObserver。');
    return MonitorBinding.instance.performanceMonitor.routeObserver;
  }

  static Interceptor get dioInterceptor {
    assert(_isInitialized, '请先调用 FlutterMonitorSDK.init() 再使用 dioInterceptor。');
    // SDK 内部负责创建拦截器实例，并传入所需的依赖（reporter）
    // 使用者无需关心其内部实现
    return MonitorDioInterceptor(MonitorBinding.instance.reporter);
  }


  static http.Client get httpClient {
    assert(_isInitialized, '请先调用 FlutterMonitorSDK.init() 再使用 httpClient。');
    // 同样，SDK 内部负责创建实例
    return MonitoredHttpClient(MonitorBinding.instance.reporter, http.Client());
  }


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
