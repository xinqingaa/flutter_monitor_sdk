import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_monitor_sdk/src/core/monitor_config.dart';
import 'package:http/http.dart' as http;

/// Reporter 是 SDK 的数据心脏，负责收集、丰富、缓存和发送所有监控事件。
class Reporter {
  final MonitorConfig _config;

  /// 缓存的设备信息，避免每次上报都重新获取。
  Map<String, dynamic>? _deviceInfo;

  // 例如，最多缓存1000条事件
  static const int maxQueueSize = 100;

  Reporter(this._config) {
    _init();
  }

  void _init() {
    // 异步获取设备信息
    _fetchDeviceInfo();

    // MODIFIED: 初始化所有在配置中提供的输出器。
    for (final output in _config.outputs) {
      output.init();
    }
  }

  /// 使用 'device_info_plus' 插件异步获取设备信息。
  /// 你可以在这里自定义需要收集的设备字段。
  Future<void> _fetchDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final info = await deviceInfoPlugin.webBrowserInfo;
        _deviceInfo = {
          // 来源: device_info_plus
          'browserName': info.browserName.name,
          'appVersion': info.appVersion,
          'platform': info.platform,
        };
      } else if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        _deviceInfo = {
          // 来源: device_info_plus
          'device': info.device,
          'model': info.model,
          'version': info.version.release,
          'isPhysicalDevice': info.isPhysicalDevice,
        };
      } else if (Platform.isIOS) {
        final info = await deviceInfoPlugin.iosInfo;
        _deviceInfo = {
          // 来源: device_info_plus
          'name': info.name,
          'model': info.model,
          'systemVersion': info.systemVersion,
          'isPhysicalDevice': info.isPhysicalDevice,
        };
      }
    } catch (e) {
      print("Failed to get device info: $e");
    }
  }

  /// 核心方法：添加一个事件到队列。
  /// 这是所有监控器与Reporter交互的入口。
  void addEvent(String eventCategory, Map<String, dynamic> data) {
    // --- 数据丰富 (Data Enrichment) ---
    // 这是关键步骤。Reporter 在这里将通用信息附加到每个事件上。
    final event = {
      // 'category': 事件的大分类 (e.g., 'error', 'performance', 'behavior')。
      // 来源: 由调用者（各个Monitor）传入。
      'category': eventCategory,

      // 'data': 事件的详细、特有数据。
      // 来源: 由调用者（各个Monitor）传入。
      'data': data,

      // --- 以下是 Reporter 自动附加的通用字段 ---
      // 'timestamp': 事件在客户端被捕获的时间 (UTC)。
      // 来源: Dart 核心库。
      'timestamp': DateTime.now().toUtc().toIso8601String(),

      // 'appKey': 在初始化时配置的应用唯一标识。
      // 来源: MonitorConfig。
      'appKey': _config.appKey,

      // 'userId': 当前用户的ID，如果设置了的话。
      // 来源: MonitorConfig (可通过 setUserId() 修改)。
      'userId': _config.userId,

      // 'customData': 开发者设置的自定义全局数据。
      // 来源: MonitorConfig (可通过 setCustomData() 修改)。
      'customData': _config.customData,

      // 'platform': 应用运行的平台 (e.g., 'web', 'android', 'ios')。
      // 来源: Flutter 核心库 (kIsWeb, Platform)。
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,

      // 'deviceInfo': 从 'device_info_plus' 插件获取的设备信息。
      // 来源: _fetchDeviceInfo() 方法。
      'deviceInfo': _deviceInfo,
    };
    // 将丰富后的事件分发给每一个输出器。
    for (final output in _config.outputs) {
      try {
        output.add(event);
      } catch (e) {
        print("Error while dispatching event to ${output.runtimeType}: $e");
      }
    }
  }


  /// 清理资源，在应用关闭时调用。
  void dispose() {
    // 调用所有输出器的 dispose 方法，让它们清理自己的资源。
    for (final output in _config.outputs) {
      output.dispose();
    }
  }
}
