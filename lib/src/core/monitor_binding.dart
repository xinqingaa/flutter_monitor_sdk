import 'monitor_config.dart';
import 'reporter.dart';
import '../modules/behavior_monitor.dart';
import '../modules/error_monitor.dart';
import '../modules/performance_monitor.dart';

/// 一个单例绑定类，它将所有监控模块粘合在一起。
/// 这是 SDK 内部的核心枢纽。
class MonitorBinding {
  // --- 单例模式设置 ---

  /// 私有构造函数，确保该类只能在内部被实例化。
  ///
  /// [config] 是SDK的配置对象。
  /// [appStartTime] 是应用启动的精确时间，用于计算启动性能。
  MonitorBinding._(this.config, {required DateTime appStartTime}) {
    // 1. 首先初始化上报器（Reporter），因为其他模块都依赖它。
    reporter = Reporter(config);

    // 2. 根据配置，决定是否初始化各个监控模块。
    if (config.enableErrorMonitor) {
      errorMonitor = ErrorMonitor(reporter);
      errorMonitor.init();
    }

    if (config.enablePerformanceMonitor) {
      performanceMonitor = PerformanceMonitor(reporter);
      // 将 App 启动时间传递给性能监控器，用于计算启动耗时。
      performanceMonitor.init(appStartTime);
    }

    if (config.enableBehaviorMonitor) {
      behaviorMonitor = BehaviorMonitor(reporter);
      // 行为监控器也可能有自己的初始化逻辑，例如监听App生命周期。
      behaviorMonitor.init();
    }
  }

  /// 静态的、私有的单例实例。
  static MonitorBinding? _instance;

  /// 公开的、用于获取单例实例的静态 getter。
  /// 如果在初始化之前就尝试访问，会触发断言错误。
  static MonitorBinding get instance {
    assert(_instance != null,
    'MonitorBinding 尚未初始化，请先调用 FlutterMonitorSDK.init()。');
    return _instance!;
  }

  // --- 初始化方法 ---

  /// 这是创建和设置 MonitorBinding 的主要入口点。
  /// 它由公开的 FlutterMonitorSDK.init() 方法调用。
  static void init({required MonitorConfig config, required DateTime appStartTime}) {
    if (_instance != null) {
      print("警告: MonitorBinding 已经被初始化过了。");
      return;
    }
    // 正确调用私有构造函数并赋值给私有实例
    _instance = MonitorBinding._(config, appStartTime: appStartTime);
  }

  // --- 可供内部访问的服务 ---

  /// SDK 的配置对象。
  final MonitorConfig config;

  /// 用于发送数据的上报服务。
  late final Reporter reporter;

  /// 错误监控服务。
  late final ErrorMonitor errorMonitor;

  /// 性能监控服务。
  late final PerformanceMonitor performanceMonitor;

  /// 行为监控服务。
  late final BehaviorMonitor behaviorMonitor;

  /// 在 App 关闭时，用于释放资源的方法。
  void dispose() {
    reporter.dispose();
  }
}
