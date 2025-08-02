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

  /// 事件队列，用于缓存待上报的事件，实现批量上报。
  final List<Map<String, dynamic>> _eventQueue = [];

  /// 定时器，用于周期性地清空并上报队列中的事件。
  Timer? _batchTimer;

  /// App生命周期监听器，用于在App退出时确保所有缓存的事件都被上报。
  late final AppLifecycleListener _lifecycleListener;

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

    // 1. 根据配置 决定是否启动定时器，每10秒尝试上报一次数据。
    if (_config.enablePeriodicReporting) {
      _batchTimer = Timer.periodic(_config.periodicReportDuration, (timer) {
        _flush();
      });
    }

    // 2. 监听App生命周期，在App隐藏、暂停或分离时，立即上报数据，防止数据丢失。
    _lifecycleListener = AppLifecycleListener(
      onHide: () => _flush(isAppExiting: true),
      onPause: () => _flush(isAppExiting: true),
      onDetach: () => _flush(isAppExiting: true),
    );
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
    // 在添加前检查队列大小
    if (_eventQueue.length >= maxQueueSize) {
      // 队列已满，丢弃最旧的事件以腾出空间
      _eventQueue.removeAt(0);
    }

    // print("event:$event");
    _eventQueue.add(event);
    // 如果队列中的事件数量达到 界限 个，也立即上报，不等10秒的定时器。
    if (_eventQueue.length >= _config.batchReportSize) {
      _flush();
    }
  }

  /// 将队列中的所有事件发送到服务器。
  Future<void> _flush({bool isAppExiting = false}) async {
    if (_eventQueue.isEmpty) return;

    // 复制队列内容，然后清空原队列，防止上报期间新事件进来导致数据错乱或丢失。
    final List<Map<String, dynamic>> eventsToSend = List.from(_eventQueue);
    _eventQueue.clear();

    try {
      // 将事件列表包装在 "events" 键下，符合服务器期望的格式。
      final body = json.encode({'events': eventsToSend});
      final headers = {'Content-Type': 'application/json'};

      final response = await http.post(
        Uri.parse(_config.serverUrl),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        print('Failed to report events: ${response.statusCode}');
        // 上报失败，将事件重新加回队列，等待下次上报。
        _eventQueue.addAll(eventsToSend);
      } else {
        print("Reported ${eventsToSend.length} events successfully.");
      }
    } catch (e) {
      print('Error reporting events: $e');
      // 发生异常（如超时、无网络），同样将事件加回队列。
      _eventQueue.addAll(eventsToSend);
    }
  }

  /// 清理资源，在应用关闭时调用。
  void dispose() {
    _batchTimer?.cancel();
    _lifecycleListener.dispose();
  }
}
