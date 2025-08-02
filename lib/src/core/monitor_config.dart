import '../outputs/monitor_output.dart';

class MonitorConfig {
  /// 应用标识
  final String appKey;
  /// 监听报错开关 默认开
  final bool enableErrorMonitor;
  /// 监听性能开关 默认开
  final bool enablePerformanceMonitor;
  /// 监听用户行为 默认开
  final bool enableBehaviorMonitor;
  /// 新增卡顿监控开关 默认开
  final bool enableJankMonitor;
  /// 用户ID，可后续设置
  String? userId;
  /// 自定义全局附加数据
  Map<String, dynamic>? customData;
  /// 新增：用于配置监控数据输出目的地的列表。
  final List<MonitorOutput> outputs;

  MonitorConfig({
    required this.appKey,
    this.enableErrorMonitor = true,
    this.enablePerformanceMonitor = true,
    this.enableBehaviorMonitor = true,
    this.enableJankMonitor = true,
    this.userId,
    this.customData,
    required this.outputs,
  });
}
