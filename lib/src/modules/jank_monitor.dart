import 'dart:math';
import 'package:flutter/scheduler.dart';
import 'package:flutter_monitor_sdk/src/core/reporter.dart';

// CPU 密集型卡顿 (覆盖得很好 ✅)
// 这是指 UI 线程被大量的计算任务占满，导致 build, layout, paint 的时间过长。
// SDK 可以捕获的场景包括：
// 复杂的 Widget 构建: 在 build 方法中进行了大量的同步计算、复杂的对象创建、数据转换等。
// 低效的列表项: 在一个长列表中（如 ListView），每个列表项（item）的 build 方法都非常耗时。当你快速滑动这个列表时，Flutter 需要在短时间内构建大量新的 item，如果每个 item 都很慢，就会产生连续的慢帧，从而被你的 SDK 捕获。
// 复杂的自定义绘制: 使用 CustomPaint 绘制非常复杂的图形，导致 paint 阶段耗时过长。
// 复杂的布局计算: 嵌套层级非常深，或者使用了大量 IntrinsicWidth/IntrinsicHeight 等需要多次布局计算的 Widget，导致 layout 阶段耗时过长。
// 简单来说：只要是 Dart 代码本身写得不够高效，导致 UI 线程忙于计算而无法在 16.7ms 内完成一帧的渲染，并且这种情况连续发生，你的 SDK 就能抓到。

// UI 线程阻塞型卡顿 (覆盖不到 ❌)
// 这是指 UI 线程被一个长时间的同步操作完全冻结，导致它在一段时间内无法响应任何事情，包括渲染新帧。
// SDK 目前无法捕获的场景包括：
// 同步 I/O 操作: 在 UI 线程上执行了文件读写、数据库查询等耗时 I/O。（这是绝对要避免的坏实践，但确实会发生）。
// 长时间的 while 循环: 正如我们之前调试时发现的，一个长的同步循环会冻结线程，而不是让帧变慢。
// 插件的同步方法调用: 调用了一个 Native 插件的同步方法，而这个 Native 方法执行了很长时间才返回。
// 为什么捕获不到？ 因为在线程被冻结期间，SchedulerBinding.instance.addTimingsCallback 根本不会被触发。当阻塞结束后，只会产生一个超长的帧，而我们的逻辑是寻找“连续的”慢帧，所以单个的“巨型帧”会被忽略。

class JankMonitor {
  final Reporter _reporter;
  final String Function()? _getCurrentPage;

  JankMonitor(this._reporter, {String Function()? getCurrentPage})
      : _getCurrentPage = getCurrentPage;

  // --- 可配置的卡顿标准 ---

  /// 1. 连续卡顿帧数阈值
  /// 当连续超过这个数量的帧都发生超时，才记录为一次有效的卡顿事件。
  /// 推荐值: 3-5。这意味着连续3帧以上都卡顿才上报。
  static const int CONSECUTIVE_JANK_THRESHOLD = 3;

  /// 2. 单帧卡顿阈值乘数
  /// 一帧的耗时超过 "帧预算 * 这个乘数"，就被认为是一帧卡顿。
  /// 推荐值: 2.0-3.0。
  static const double JANK_FRAME_TIME_MULTIPLIER = 2.0;

  // --- 内部状态变量 ---

  /// 记录当前连续卡顿的帧数。
  int _consecutiveJankFrames = 0;
  /// 记录在当前卡顿序列中，耗时最长的一帧的时间。
  double _maxJankDurationInSequence = 0;
  /// 记录当前卡顿序列的总耗时。
  double _totalJankDurationInSequence = 0;


  void init() {
    const double defaultRefreshRate = 60.0;
    final double refreshRate = SchedulerBinding.instance.window.display.refreshRate;
    final double frameBudgetMs = 1000 / (refreshRate > 0 ? refreshRate : defaultRefreshRate);
    final double jankThresholdMs = frameBudgetMs * JANK_FRAME_TIME_MULTIPLIER;

    print(
        "JankMonitor initialized with new standard. Frame budget: ${frameBudgetMs.toStringAsFixed(2)}ms, Single frame jank threshold: ${jankThresholdMs.toStringAsFixed(2)}ms, Consecutive threshold: $CONSECUTIVE_JANK_THRESHOLD frames.");

    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final totalDuration = timing.totalSpan.inMicroseconds / 1000.0;

        // 判断当前帧是否卡顿
        if (totalDuration > jankThresholdMs) {
          // 如果是卡顿帧，累加计数器和耗时
          _consecutiveJankFrames++;
          _maxJankDurationInSequence = max(_maxJankDurationInSequence, totalDuration);
          _totalJankDurationInSequence += totalDuration;
        } else {
          // 如果当前帧是流畅的，检查之前是否有连续卡顿
          _checkAndReportJankSequence();
        }
      }
    });
  }

  /// 检查并上报卡顿序列
  void _checkAndReportJankSequence() {
    // 如果连续卡顿的帧数达到了我们设定的阈值
    if (_consecutiveJankFrames >= CONSECUTIVE_JANK_THRESHOLD) {
      final data = {
        'type': 'jank_sequence', // 新的事件类型，表示卡顿序列
        'page': _getCurrentPage?.call() ?? 'unknown',
        'jank_count': _consecutiveJankFrames, // 卡顿持续了多少帧
        'max_duration_ms': _maxJankDurationInSequence, // 这个序列中最卡的一帧耗时
        'average_duration_ms': _totalJankDurationInSequence / _consecutiveJankFrames, // 平均每帧的耗时
      };
      _reporter.addEvent('performance', data);
    }

    // 无论是否上报，只要流畅帧出现，就重置所有状态
    _resetJankState();
  }

  /// 重置状态
  void _resetJankState() {
    _consecutiveJankFrames = 0;
    _maxJankDurationInSequence = 0;
    _totalJankDurationInSequence = 0;
  }
}
