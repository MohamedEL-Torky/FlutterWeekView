import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter_week_view/src/controller.dart';
import 'package:flutter_week_view/src/day_view.dart';
import 'package:flutter_week_view/src/event.dart';
import 'package:flutter_week_view/src/headers.dart';
import 'package:flutter_week_view/src/week_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Contains some useful methods.
class Utils {
  /// Makes the specified number to have at least two digits by adding a leading zero if needed.
  static String addLeadingZero(int number) =>
      (number < 10 ? '0' : '') + number.toString();

  /// Checks whether the provided date is the same year, month and day than the target date.
  static bool sameDay(DateTime date, [DateTime target]) {
    target = target ?? DateTime.now();
    return target.year == date.year &&
        target.month == date.month &&
        target.day == date.day;
  }

  /// Removes the last word from a string.
  static String removeLastWord(String string) {
    List<String> words = string.split(' ');
    if (words.isEmpty) {
      return '';
    }

    return words.getRange(0, words.length - 1).join(' ');
  }
}

/// Contains default builders and formatters.
class DefaultBuilders {
  /// Formats a day.
  static String defaultDateFormatter(int year, int month, int day) =>
      year.toString() +
      '-' +
      Utils.addLeadingZero(month) +
      '-' +
      Utils.addLeadingZero(day);

  /// Formats a hour.
  //TODO : handle mins
  static String defaultHourFormatter(int h, int m) {
    if (h > 11) {
      if (h == 12) {
        return "$h:${m > 9 ? '' : 0}$m PM";
      } else {
        if (h > 21) {
          return "${h - 12}:${m > 9 ? '' : 0}$m PM";
        } else {
          return "0${h - 12}:${m > 9 ? '' : 0}$m PM";
        }
      }
    } else {
      if (h > 9) {
        return "$h:${m > 9 ? '' : 0}$m AM";
      } else {
        return "0$h:${m > 9 ? '' : 0}$m AM";
      }
    }
  }

  /// Builds an event text widget in order to put it in a week view.
  static Widget defaultEventTextBuilder(FlutterWeekViewEvent event,
      BuildContext context, DayView dayView, double height, double width) {
    List<TextSpan> text = [
      TextSpan(
        text: event.title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      TextSpan(
        text: '\n${event.isTimeBox ? '\n' : ''}' +
            dayView.hourFormatter(event.start.hour, event.start.minute) +
            '${event.isTimeBox ? '\n' : ''} - ${event.isTimeBox ? '\n' : ''}' +
            dayView.hourFormatter(event.end.hour, event.end.minute) +
            '\n\n',
      ),
      TextSpan(
        text: event.description,
      ),
    ];

    bool exceedHeight;
    while (exceedHeight ?? true) {
      exceedHeight = _exceedHeight(text, event.textStyle, height, width);
      if (exceedHeight == null || !exceedHeight) {
        if (exceedHeight == null) {
          text.clear();
        }
        break;
      }

      if (!_ellipsize(text)) {
        break;
      }
    }

    return RichText(
      text: TextSpan(
        children: text,
        style: event.textStyle,
      ),
    );
  }

  /// Builds a date according to a list.
  static DateTime defaultDateCreator(List<DateTime> dates, int index) =>
      dates[index];

  static DateTime customDateCreator(DateTime date) => date;

  /// Builds a day view in order to put it in a week view.
  static DayView defaultDayViewBuilder(BuildContext context, WeekView weekView,
          DateTime date, DayViewController controller,
          {@required Color daysColor, @required Color sameDayColor}) =>
      DayView(
        date: date,
        events: weekView.events,
        hoursColumnWidth: 0,
        controller: controller,
        inScrollableWidget: false,
        dayBarHeight: 0,
        userZoomable: false,
        scrollToCurrentTime: false,
        daysColor: daysColor,
        sameDayColor: sameDayColor,
      );

  /// Builds a day bar in order to put it in a week view.
  static DayBar defaultDayBarBuilder(
          BuildContext context, WeekView weekView, DateTime date) =>
      DayBar(
        date: date,
        height: weekView.dayBarHeight,
        backgroundColor: weekView.dayBarBackgroundColor,
      );

  /// Builds a hours column widget in order to put it in a week view.
  static HoursColumn defaultHoursColumnBuilder(
          BuildContext context, WeekView weekView, double hourRowHeight) =>
      weekView.hoursColumnWidth <= 0
          ? const SizedBox.shrink()
          : HoursColumn(
              hourRowHeight: hourRowHeight,
              width: weekView.hoursColumnWidth,
            );

  /// Returns whether this input exceeds the specified height.
  static bool _exceedHeight(
      List<TextSpan> input, TextStyle textStyle, double height, double width) {
    double fontSize = textStyle?.fontSize ?? 14;
    int maxLines = height ~/ ((textStyle?.height ?? 1.2) * fontSize);
    if (maxLines == 0) {
      return null;
    }

    TextPainter painter = TextPainter(
      text: TextSpan(
        children: input,
        style: textStyle,
      ),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    );
    painter.layout(maxWidth: width);
    return painter.didExceedMaxLines;
  }

  /// Ellipsizes the input.
  static bool _ellipsize(List<TextSpan> input, [String ellipse = '…']) {
    if (input.isEmpty) {
      return false;
    }

    TextSpan last = input.last;
    String text = last.text;
    if (text.isEmpty || text == ellipse) {
      input.removeLast();

      if (text == ellipse) {
        _ellipsize(input, ellipse);
      }
      return true;
    }

    String truncatedText;
    if (text.endsWith('\n')) {
      truncatedText = text.substring(0, text.length - 1) + ellipse;
    } else {
      truncatedText = Utils.removeLastWord(text);
      truncatedText =
          truncatedText.substring(0, math.max(0, truncatedText.length - 2)) +
              ellipse;
    }

    input[input.length - 1] = TextSpan(
      text: truncatedText,
      style: last.style,
    );

    return true;
  }
}

/// Allows to not show the glow effect in scrollable widgets.
class NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }

  /// Applies this behavior to a scrollable widget.
  static Widget noGlow({
    Widget child,
  }) =>
      ScrollConfiguration(
        behavior: NoGlowBehavior(),
        child: child,
      );
}

/// A scroll physics that always lands on specific points.
class MagnetScrollPhysics extends ScrollPhysics {
  /// The fixed item size.
  final double itemSize;

  /// Creates a new magnet scroll physics instance.
  const MagnetScrollPhysics({
    ScrollPhysics parent,
    @required this.itemSize,
  }) : super(parent: parent);

  @override
  MagnetScrollPhysics applyTo(ScrollPhysics ancestor) {
    return MagnetScrollPhysics(
      parent: buildParent(ancestor),
      itemSize: itemSize,
    );
  }

  @override
  Simulation createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // Scenario 1:
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at the scrollable's boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    // Create a test simulation to see where it would have ballistically fallen
    // naturally without settling onto items.
    final Simulation testFrictionSimulation =
        super.createBallisticSimulation(position, velocity);

    // Scenario 2:
    // If it was going to end up past the scroll extent, defer back to the
    // parent physics' ballistics again which should put us on the scrollable's
    // boundary.
    if (testFrictionSimulation != null &&
        (testFrictionSimulation.x(double.infinity) ==
                position.minScrollExtent ||
            testFrictionSimulation.x(double.infinity) ==
                position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    // From the natural final position, find the nearest item it should have
    // settled to.
    final int settlingItemIndex = _getItemFromOffset(
      offset: testFrictionSimulation?.x(double.infinity) ?? position.pixels,
      minScrollExtent: position.minScrollExtent,
      maxScrollExtent: position.maxScrollExtent,
    );

    final double settlingPixels = settlingItemIndex * itemSize;

    // Scenario 3:
    // If there's no velocity and we're already at where we intend to land,
    // do nothing.
    if (velocity.abs() < tolerance.velocity &&
        (settlingPixels - position.pixels).abs() < tolerance.distance) {
      return null;
    }

    // Scenario 4:
    // If we're going to end back at the same item because initial velocity
    // is too low to break past it, use a spring simulation to get back.
    if (settlingItemIndex ==
        _getItemFromOffset(
          offset: position.pixels,
          minScrollExtent: position.minScrollExtent,
          maxScrollExtent: position.maxScrollExtent,
        )) {
      return SpringSimulation(
        spring,
        position.pixels,
        settlingPixels,
        velocity,
        tolerance: tolerance,
      );
    }

    // Scenario 5:
    // Create a new friction simulation except the drag will be tweaked to land
    // exactly on the item closest to the natural stopping point.
    return FrictionSimulation.through(
      position.pixels,
      settlingPixels,
      velocity,
      tolerance.velocity * velocity.sign,
    );
  }

  /// Returns the item index from the specified offset.
  int _getItemFromOffset({
    double offset,
    double minScrollExtent,
    double maxScrollExtent,
  }) =>
      (_clipOffsetToScrollableRange(offset, minScrollExtent, maxScrollExtent) /
              itemSize)
          .round();

  /// Clips the specified offset to the scrollable range.
  double _clipOffsetToScrollableRange(
    double offset,
    double minScrollExtent,
    double maxScrollExtent,
  ) =>
      math.min(math.max(offset, minScrollExtent), maxScrollExtent);
}

/// A scroll controller that allows to use the [silentJumpTo] method.
class SilentScrollController extends ScrollController {
  /// Creates a new silent scroll controller instance.
  SilentScrollController({
    double initialScrollOffset = 0.0,
    bool keepScrollOffset = true,
    String debugLabel,
  }) : super(
          initialScrollOffset: initialScrollOffset,
          keepScrollOffset: keepScrollOffset,
          debugLabel: debugLabel,
        );

  @override
  _SilentScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition oldPosition,
  ) {
    return _SilentScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }

  /// Silently jumps to the specified position.
  void silentJumpTo(double pixels) {
    assert(positions.isNotEmpty,
        'ScrollController not attached to any scroll views.');
    List.from(positions).forEach((position) => position.silentJumpTo(pixels));
  }
}

/// A scroll position that allows to use [silentJumpTo].
class _SilentScrollPosition extends ScrollPositionWithSingleContext {
  /// Creates a new scroll position instance.
  _SilentScrollPosition({
    @required ScrollPhysics physics,
    @required ScrollContext context,
    double initialPixels = 0.0,
    bool keepScrollOffset = true,
    ScrollPosition oldPosition,
    String debugLabel,
  }) : super(
          physics: physics,
          context: context,
          initialPixels: initialPixels,
          keepScrollOffset: keepScrollOffset,
          oldPosition: oldPosition,
          debugLabel: debugLabel,
        );

  /// Silently jumps to the specified position.
  void silentJumpTo(double value) {
    if (pixels != value) {
      forcePixels(value);
    }
  }
}
