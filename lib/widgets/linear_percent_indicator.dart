import 'package:flutter/material.dart';
import 'package:SnipSnap/configs/app_globals.dart';
import 'package:SnipSnap/main.dart';

enum LinearStrokeCap { butt, round, roundAll }

/// Linear percent indicator.
///
/// Forked from https://github.com/diegoveloper/flutter_percent_indicator
/// If you need the whole package add it as a dependency package in your flutter
/// project:
///
/// dependencies:
///   percent_indicator: "^2.1.7"
///
/// ignore: must_be_immutable
class LinearPercentIndicator extends StatefulWidget {
  LinearPercentIndicator(
      {Key key,
      this.percent = 0.0,
      this.lineHeight = 5.0,
      this.width,
      this.backgroundColor = const Color(0xFFB8C7CB),
      Color progressColor,
      this.animation = false,
      this.animationDuration = 500,
      this.animateFromLastPercent = false,
      this.isRTL,
      this.leading,
      this.trailing,
      this.center,
      this.addAutomaticKeepAlive = true,
      this.linearStrokeCap,
      this.padding = const EdgeInsets.symmetric(horizontal: 10.0),
      this.alignment = MainAxisAlignment.start,
      this.maskFilter,
      this.clipLinearGradient = false,
      this.curve = Curves.linear,
      this.restartAnimation = false})
      : super(key: key) {
    _progressColor = progressColor ?? Colors.red;

    assert(curve != null);

    if (percent < 0.0 || percent > 1.0) {
      throw Exception('Percent value must be a double between 0.0 and 1.0');
    }
  }

  ///Percent value between 0.0 and 1.0
  final double percent;
  final double width;

  ///Height of the line
  final double lineHeight;

  ///First color applied to the complete line
  final Color backgroundColor;

  Color get progressColor => _progressColor;

  Color _progressColor;

  ///true if you want the Line to have animation
  final bool animation;

  ///duration of the animation in milliseconds, It only applies if animation attribute is true
  final int animationDuration;

  ///widget at the left of the Line
  final Widget leading;

  ///widget at the right of the Line
  final Widget trailing;

  ///widget inside the Line
  final Widget center;

  ///The kind of finish to place on the end of lines drawn, values supported: butt, round, roundAll
  final LinearStrokeCap linearStrokeCap;

  ///alignment of the Row (leading-widget-center-trailing)
  final MainAxisAlignment alignment;

  ///padding to the LinearPercentIndicator
  final EdgeInsets padding;

  /// set true if you want to animate the linear from the last percent value you set
  final bool animateFromLastPercent;

  /// set false if you don't want to preserve the state of the widget
  final bool addAutomaticKeepAlive;

  /// set true if you want to animate the linear from the right to left (RTL)
  final bool isRTL;

  /// Creates a mask filter that takes the progress shape being drawn and blurs it.
  final MaskFilter maskFilter;

  /// Set true if you want to display only part of [linearGradient] based on percent value
  /// (ie. create 'VU effect'). If no [linearGradient] is specified this option is ignored.
  final bool clipLinearGradient;

  /// set a linear curve animation type
  final Curve curve;

  /// set true when you want to restart the animation, it restarts only when reaches 1.0 as a value
  /// defaults to false
  final bool restartAnimation;

  @override
  _LinearPercentIndicatorState createState() => _LinearPercentIndicatorState();
}

class _LinearPercentIndicatorState extends State<LinearPercentIndicator>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  AnimationController _animationController;
  Animation<double> _animation;
  double _percent = 0.0;

  @override
  void dispose() {
    if (_animationController != null) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    if (widget.animation) {
      _animationController = AnimationController(
          vsync: this,
          duration: Duration(milliseconds: widget.animationDuration));
      _animation = Tween<double>(begin: 0.0, end: widget.percent).animate(
        CurvedAnimation(parent: _animationController, curve: widget.curve),
      )..addListener(() {
          setState(() => _percent = _animation.value);
          if (widget.restartAnimation && _percent == 1.0) {
            _animationController.repeat(min: 0, max: 1.0);
          }
        });
      _animationController.forward();
    } else {
      _updateProgress();
    }
    super.initState();
  }

  @override
  void didUpdateWidget(LinearPercentIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      if (_animationController != null) {
        _animationController.duration =
            Duration(milliseconds: widget.animationDuration);
        _animation = Tween<double>(
                begin: widget.animateFromLastPercent ? oldWidget.percent : 0.0,
                end: widget.percent)
            .animate(
          CurvedAnimation(parent: _animationController, curve: widget.curve),
        );
        _animationController.forward(from: 0.0);
      } else {
        _updateProgress();
      }
    }
  }

  void _updateProgress() {
    setState(() => _percent = widget.percent);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final List<Widget> items = <Widget>[];
    if (widget.leading != null) {
      items.add(widget.leading);
    }
    final bool hasSetWidth = widget.width != null;
    final Container containerWidget = Container(
      width: hasSetWidth ? widget.width : double.infinity,
      height: widget.lineHeight,
      padding: widget.padding,
      child: CustomPaint(
        painter: LinearPainter(
          isRTL: widget.isRTL ?? getIt.get<AppGlobals>().isRTL,
          progress: _percent,
          center: widget.center,
          progressColor: widget.progressColor,
          backgroundColor: widget.backgroundColor,
          linearStrokeCap: widget.linearStrokeCap,
          lineWidth: widget.lineHeight,
          maskFilter: widget.maskFilter,
          clipLinearGradient: widget.clipLinearGradient,
        ),
        child: (widget.center != null)
            ? Center(child: widget.center)
            : Container(),
      ),
    );

    if (hasSetWidth) {
      items.add(containerWidget);
    } else {
      items.add(Expanded(child: containerWidget));
    }
    if (widget.trailing != null) {
      items.add(widget.trailing);
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        child: Row(
          mainAxisAlignment: widget.alignment,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: items,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.addAutomaticKeepAlive;
}

class LinearPainter extends CustomPainter {
  LinearPainter({
    this.lineWidth,
    this.progress,
    this.center,
    this.isRTL,
    this.progressColor,
    this.backgroundColor,
    this.linearStrokeCap = LinearStrokeCap.butt,
    this.linearGradient,
    this.maskFilter,
    this.clipLinearGradient,
  }) {
    _paintBackground.color = backgroundColor;
    _paintBackground.style = PaintingStyle.stroke;
    _paintBackground.strokeWidth = lineWidth;

    _paintLine.color = progress.toString() == '0.0'
        ? progressColor.withOpacity(0.0)
        : progressColor;
    _paintLine.style = PaintingStyle.stroke;
    _paintLine.strokeWidth = lineWidth;

    if (linearStrokeCap == LinearStrokeCap.round) {
      _paintLine.strokeCap = StrokeCap.round;
    } else if (linearStrokeCap == LinearStrokeCap.butt) {
      _paintLine.strokeCap = StrokeCap.butt;
    } else {
      _paintLine.strokeCap = StrokeCap.round;
      _paintBackground.strokeCap = StrokeCap.round;
    }
  }

  final Paint _paintBackground = Paint();
  final Paint _paintLine = Paint();
  final double lineWidth;
  final double progress;
  final Widget center;
  final bool isRTL;
  final Color progressColor;
  final Color backgroundColor;
  final LinearStrokeCap linearStrokeCap;
  final LinearGradient linearGradient;
  final MaskFilter maskFilter;
  final bool clipLinearGradient;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset start = Offset(0.0, size.height / 2);
    final Offset end = Offset(size.width, size.height / 2);
    canvas.drawLine(start, end, _paintBackground);

    if (maskFilter != null) {
      _paintLine.maskFilter = maskFilter;
    }

    if (isRTL) {
      final double xProgress = size.width - size.width * progress;
      if (linearGradient != null) {
        _paintLine.shader = _createGradientShaderRightToLeft(size, xProgress);
      }
      canvas.drawLine(end, Offset(xProgress, size.height / 2), _paintLine);
    } else {
      final double xProgress = size.width * progress;
      if (linearGradient != null) {
        _paintLine.shader = _createGradientShaderLeftToRight(size, xProgress);
      }
      canvas.drawLine(start, Offset(xProgress, size.height / 2), _paintLine);
    }
  }

  Shader _createGradientShaderRightToLeft(Size size, double xProgress) {
    final Offset shaderEndPoint =
        clipLinearGradient ? Offset.zero : Offset(xProgress, size.height);
    return linearGradient.createShader(
      Rect.fromPoints(
        Offset(size.width, size.height),
        shaderEndPoint,
      ),
    );
  }

  Shader _createGradientShaderLeftToRight(Size size, double xProgress) {
    final Offset shaderEndPoint = clipLinearGradient
        ? Offset(size.width, size.height)
        : Offset(xProgress, size.height);
    return linearGradient.createShader(
      Rect.fromPoints(
        Offset.zero,
        shaderEndPoint,
      ),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
