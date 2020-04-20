import 'dart:math' as math;
import 'package:flutter_week_view/src/controller.dart';
import 'package:flutter_week_view/src/day_view.dart';
import 'package:flutter_week_view/src/event.dart';
import 'package:flutter_week_view/src/headers.dart';
import 'package:flutter_week_view/src/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Builds a day view.
typedef DayViewBuilder = DayView Function(BuildContext context,
    WeekView weekView, DateTime date, DayViewController dayViewController,
    {@required Color daysColor, @required Color sameDayColor});

/// Creates a date according to the specified index.
typedef DateCreator = DateTime Function(int index);

/// A (scrollable) week view which is able to display events, zoom and un-zoom and more !
class WeekView extends ZoomableHeadersWidget<WeekViewController> {
  /// The number of events.
  final int dateCount;

  final Function onPageChange;

  /// The date creator.
  final DateCreator dateCreator;

  /// The events.
  final List<FlutterWeekViewEvent> events;

  /// The day view builder.
  final DayViewBuilder dayViewBuilder;

  /// A day view width.
  final double dayViewWidth;

  final List<DateTime> dates;

  final Color backgroundColor;
  final Color lineColor;

  final Color sameDayColor;
  final Color daysColor;

  final TextStyle sameDaytitleStyle;
  final TextStyle otherDaytitleStyle;

  /// Creates a new week view instance.
  WeekView({
    this.otherDaytitleStyle,
    this.sameDaytitleStyle,
    @required this.sameDayColor,
    @required this.daysColor,
    List<FlutterWeekViewEvent> events,
    @required this.onPageChange,
    @required this.dates,
    this.dayViewBuilder = DefaultBuilders.defaultDayViewBuilder,
    this.dayViewWidth,
    this.backgroundColor,
    this.lineColor,
    DateFormatter dateFormatter,
    HourFormatter hourFormatter,
    WeekViewController controller,
    TextStyle dayBarTextStyle,
    double dayBarHeight,
    Color dayBarBackgroundColor,
    TextStyle hoursColumnTextStyle,
    double hoursColumnWidth,
    Color hoursColumnBackgroundColor,
    double hourRowHeight,
    bool inScrollableWidget = true,
    int initialHour,
    int initialMinute,
    bool scrollToCurrentTime = true,
    bool userZoomable = true,
  })  : assert(dates != null && dates.isNotEmpty),
        assert(dayViewBuilder != null),
        dateCount = dates?.length ?? 0,
        dateCreator =
            ((index) => DefaultBuilders.defaultDateCreator(dates, index)),
        events = events ?? [],
        super(
          controller:
              controller ?? WeekViewController(dayViewsCount: dates.length),
          dateFormatter: dateFormatter ?? DefaultBuilders.defaultDateFormatter,
          hourFormatter: hourFormatter ?? DefaultBuilders.defaultHourFormatter,
          dayBarTextStyle: dayBarTextStyle,
          dayBarHeight: dayBarHeight,
          dayBarBackgroundColor: dayBarBackgroundColor,
          hoursColumnTextStyle: hoursColumnTextStyle,
          hoursColumnWidth: hoursColumnWidth,
          hoursColumnBackgroundColor: hoursColumnBackgroundColor,
          hourRowHeight: hourRowHeight,
          inScrollableWidget: inScrollableWidget,
          initialHour: initialHour,
          initialMinute: initialMinute,
          scrollToCurrentTime: scrollToCurrentTime,
          userZoomable: userZoomable,
        );

  /// Creates a new week view instance.
  WeekView.builder({
    this.otherDaytitleStyle,
    this.sameDaytitleStyle,
    @required this.sameDayColor,
    @required this.daysColor,
    this.backgroundColor,
    this.lineColor,
    this.dates,
    List<FlutterWeekViewEvent> events,
    this.dateCount,
    @required this.onPageChange,
    @required this.dateCreator,
    this.dayViewBuilder = DefaultBuilders.defaultDayViewBuilder,
    this.dayViewWidth,
    DateFormatter dateFormatter,
    HourFormatter hourFormatter,
    WeekViewController controller,
    TextStyle dayBarTextStyle,
    double dayBarHeight,
    Color dayBarBackgroundColor,
    TextStyle hoursColumnTextStyle,
    double hoursColumnWidth,
    Color hoursColumnBackgroundColor,
    double hourRowHeight,
    bool inScrollableWidget = true,
    int initialHour,
    int initialMinute,
    bool scrollToCurrentTime = true,
    bool userZoomable = true,
  })  : assert(dateCount == null || dateCount >= 0),
        assert(dateCreator != null),
        assert(dayViewBuilder != null),
        events = events ?? [],
        super(
          controller:
              controller ?? WeekViewController(dayViewsCount: dateCount),
          dateFormatter: dateFormatter ?? DefaultBuilders.defaultDateFormatter,
          hourFormatter: hourFormatter ?? DefaultBuilders.defaultHourFormatter,
          dayBarTextStyle: dayBarTextStyle,
          dayBarHeight: dayBarHeight,
          dayBarBackgroundColor: dayBarBackgroundColor,
          hoursColumnTextStyle: hoursColumnTextStyle,
          hoursColumnWidth: hoursColumnWidth,
          hoursColumnBackgroundColor: hoursColumnBackgroundColor,
          hourRowHeight: hourRowHeight,
          inScrollableWidget: inScrollableWidget,
          initialHour: initialHour,
          initialMinute: initialMinute,
          scrollToCurrentTime: scrollToCurrentTime,
          userZoomable: userZoomable,
        );

  @override
  State<StatefulWidget> createState() => _WeekViewState();
}

/// The week view state.
class _WeekViewState
    extends ZoomableHeadersWidgetState<WeekView, WeekViewController> {
  /// A day view width.
  double dayViewWidth;

  static TextStyle todayStyle;
  TextStyle otherDayStyle = const TextStyle(fontSize: 25);

  @override
  void initState() {
    super.initState();
    otherDayStyle = widget.otherDaytitleStyle ?? const TextStyle(fontSize: 25);
    todayStyle = widget.sameDaytitleStyle ??
        const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 25, color: Colors.blue);
    _pageController = PageController(
      initialPage: 1,
      viewportFraction: 0.75,
    );

    _today = widget.dates[1];

    dayViewWidth = widget.dayViewWidth;
    if (dayViewWidth != null) {
      scheduleScrolls();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      double widgetWidth = (context.findRenderObject() as RenderBox).size.width;
      setState(() {
        dayViewWidth = widgetWidth - widget.hoursColumnWidth;
        scheduleScrolls();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (dayViewWidth == null) {
      return const SizedBox.expand();
    }

    return createMainWidget();
  }

  /// Creates the main widget.
  Widget createMainWidget() {
    Widget weekViewStack = createWeekViewStack();
    if (widget.inScrollableWidget) {
      weekViewStack = NoGlowBehavior.noGlow(
        child: Column(
          children: <Widget>[
            Text(
              monthFormater.format(_today),
              style: monthFormater.format(_today) ==
                      monthFormater.format(DateTime.now())
                  ? todayStyle
                  : otherDayStyle,
            ),
            Container(
              height: 1,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10, bottom: 10),
              decoration: BoxDecoration(
                color: widget.lineColor ?? Colors.grey,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.controller.verticalScrollController,
                child: weekViewStack,
              ),
            ),
          ],
        ),
      );
    }

    if (isZoomable) {
      weekViewStack = GestureDetector(
        onScaleStart: (_) => widget.controller.scaleStart(),
        onScaleUpdate: (details) => widget.controller.scaleUpdate(details),
        child: weekViewStack,
      );
    }

    return Stack(
      children: [
        weekViewStack,
      ],
    );
  }

  DateFormat monthFormater = DateFormat('yMMMMd');

  DateTime _today;
  PageController _pageController;

  dynamic itemBuilder(c, i) {
    return Container();
  }

  /// Creates the week view stack.
  Widget createWeekViewStack() => Column(
        children: <Widget>[
          Row(
            children: [
              SingleChildScrollView(
                controller: widget.controller.horizontalScrollController,
              ),
              HoursColumn.fromHeadersWidget(parent: widget),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Container(
                      color: widget.backgroundColor,
                      child: SizedBox(
                        height: calculateHeight(),
                        width: dayViewWidth,
                        child: PageView.builder(
                          physics: widget.inScrollableWidget
                              ? MagnetScrollPhysics(itemSize: dayViewWidth)
                              : const NeverScrollableScrollPhysics(),
                          itemCount: widget.dates.length,
                          scrollDirection: Axis.horizontal,
                          controller: _pageController,
                          onPageChanged: (page) {
                            setState(() {
                              _today = widget.dates[page];
                              widget.onPageChange(page, _pageController);
                            });
                          },
                          itemBuilder: (BuildContext buildContext, int index) {
                            return AnimatedBuilder(
                              animation: _pageController,
                              child: itemBuilder(context, index),
                              builder: (BuildContext context, child) {
                                // on the first render, the pageController.page is null,
                                // this is a dirty hack
                                if (_pageController.position.minScrollExtent ==
                                        null ||
                                    _pageController.position.maxScrollExtent ==
                                        null) {
                                  Future.delayed(
                                      const Duration(microseconds: 1), () {
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  });
                                  return Container();
                                }
                                double value = _pageController.page - index;
                                value =
                                    (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);

                                final double height = calculateHeight();
                                final double distortionValue =
                                    Curves.easeOut.transform(value);

                                return Column(
                                  children: <Widget>[
                                    Expanded(
                                      child: Center(
                                        child: SizedBox(
                                          height: distortionValue * height,
                                          child: Card(
                                            child: Container(
                                              child: createDayView(index),
                                            ),
                                            elevation:
                                                _pageController.page == index
                                                    ? 7
                                                    : 0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );

  /// Creates the day view at the specified index.
  Widget createDayView(int index) => SizedBox(
        width: dayViewWidth,
        child: widget.dayViewBuilder(
          context,
          widget,
          widget.dateCreator(index),
          widget.controller.dayViewControllers[index],
          daysColor: widget.daysColor,
          sameDayColor: widget.sameDayColor,
        ),
      );

  @override
  bool get shouldScrollToCurrentTime {
    if (widget.dateCount == null) {
      return false;
    }

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    bool hasCurrentDay = false;
    if (widget.dateCount != null) {
      for (int i = 0; i < widget.dateCount; i++) {
        if (widget.dateCreator(i) == today) {
          hasCurrentDay = true;
          break;
        }
      }
    }

    return dayViewWidth != null &&
        super.shouldScrollToCurrentTime &&
        hasCurrentDay;
  }

  @override
  void scrollToCurrentTime() {
    super.scrollToCurrentTime();

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    int index = 0;
    if (widget.dateCount != null) {
      for (; index < widget.dateCount; index++) {
        if (widget.dateCreator(index) == today) {
          break;
        }
      }
    }

    double topOffset = calculateTopOffset(now.hour, now.minute);
    double leftOffset = dayViewWidth * index;

    widget.controller.verticalScrollController.jumpTo(math.min(topOffset,
        widget.controller.verticalScrollController.position.maxScrollExtent));
    widget.controller.horizontalScrollController.jumpTo(math.min(leftOffset,
        widget.controller.horizontalScrollController.position.maxScrollExtent));
  }
}

/// A day bar that scroll itself according to the current week view scroll position.
