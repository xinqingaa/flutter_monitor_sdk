class MonitorConfig {
  final String serverUrl; // 上报服务器地址
  final String appKey;    // 应用标识

  final bool enableErrorMonitor; // 监听报错
  final bool enablePerformanceMonitor; // 监听性能
  final bool enableBehaviorMonitor; // 监听用户行为

  final bool enablePeriodicReporting; // 是否开启定时上报，默认为 true
  final Duration periodicReportDuration; // 定时上报的间隔，默认为 20 秒
  final int batchReportSize; // 批量上报的事件数量阈值，默认为 10 条


  String? userId;         // 用户ID，可后续设置
  Map<String, dynamic>? customData; // 自定义全局附加数据

  MonitorConfig({
    required this.serverUrl,
    required this.appKey,
    this.enableErrorMonitor = true,
    this.enablePerformanceMonitor = true,
    this.enableBehaviorMonitor = true,
    this.enablePeriodicReporting = true,
    this.periodicReportDuration = const Duration(seconds: 20),
    this.batchReportSize = 10,
    this.userId,
    this.customData,
  });
}
