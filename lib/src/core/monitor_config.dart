class MonitorConfig {
  final String serverUrl; // 上报服务器地址
  final String appKey;    // 应用标识
  final bool enableErrorMonitor;
  final bool enablePerformanceMonitor;
  final bool enableBehaviorMonitor;
  String? userId;         // 用户ID，可后续设置
  Map<String, dynamic>? customData; // 自定义全局附加数据

  MonitorConfig({
    required this.serverUrl,
    required this.appKey,
    this.enableErrorMonitor = true,
    this.enablePerformanceMonitor = true,
    this.enableBehaviorMonitor = true,
    this.userId,
    this.customData,
  });
}
