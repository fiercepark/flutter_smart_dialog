import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/src/data/base_controller.dart';

class AttachDialogWidget extends StatefulWidget {
  const AttachDialogWidget({
    Key? key,
    required this.child,
    required this.targetContext,
    required this.controller,
    required this.animationDuration,
    required this.isUseAnimation,
    required this.onBgTap,
    required this.alignment,
    required this.isPenetrate,
    required this.isLoading,
    required this.maskColor,
    required this.clickBgDismiss,
    this.maskWidget,
  }) : super(key: key);

  ///target context
  final BuildContext targetContext;

  /// 是否使用动画
  final bool isUseAnimation;

  ///动画时间
  final Duration animationDuration;

  final Widget child;

  final AttachDialogController controller;

  /// 点击背景
  final VoidCallback onBgTap;

  /// 内容控件方向
  final AlignmentGeometry alignment;

  /// 是否穿透背景,交互背景之后控件
  final bool isPenetrate;

  /// 是否使用Loading情况；true:内容体使用渐隐动画  false：内容体使用缩放动画
  /// 仅仅针对中间位置的控件
  final bool isLoading;

  /// 遮罩颜色
  final Color maskColor;

  /// 自定义遮罩Widget
  final Widget? maskWidget;

  /// 点击遮罩，是否关闭dialog---true：点击遮罩关闭dialog，false：不关闭
  final bool clickBgDismiss;

  @override
  _AttachDialogWidgetState createState() => _AttachDialogWidgetState();
}

class _AttachDialogWidgetState extends State<AttachDialogWidget>
    with SingleTickerProviderStateMixin {
  late double _opacity;

  late AnimationController _controller;

  /// 处理下内容widget动画放心
  Offset? _offset;

  @override
  void initState() {
    //处理背景动画和内容widget动画设置
    _opacity = widget.isUseAnimation ? 0.0 : 1.0;
    _controller =
        AnimationController(vsync: this, duration: widget.animationDuration);
    _controller.forward();
    _dealContentAnimate();

    //开启背景动画的效果
    Future.delayed(Duration(milliseconds: 10), () {
      _opacity = 1.0;
      if (mounted) setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      //暗色背景widget动画
      _buildBgAnimation(
        onPointerUp: widget.clickBgDismiss ? widget.onBgTap : null,
        child: (widget.maskWidget != null && !widget.isPenetrate)
            ? widget.maskWidget
            : Container(color: widget.isPenetrate ? null : widget.maskColor),
      ),

      //内容Widget动画
      Container(
        alignment: widget.alignment,
        child: widget.isUseAnimation ? _buildBodyAnimation() : widget.child,
      ),
    ]);
  }

  AnimatedOpacity _buildBgAnimation({
    required void Function()? onPointerUp,
    required Widget? child,
  }) {
    return AnimatedOpacity(
      duration: widget.animationDuration,
      curve: Curves.linear,
      opacity: _opacity,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerUp: (event) => onPointerUp?.call(),
        child: child,
      ),
    );
  }

  Widget _buildBodyAnimation() {
    return widget.alignment == Alignment.center
        //中间弹窗动画的使用需要分情况 渐隐和缩放俩种
        ? (widget.isLoading
            ? AnimatedOpacity(
                duration: widget.animationDuration,
                curve: Curves.linear,
                opacity: _opacity,
                child: widget.child,
              )
            : ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.linear,
                ),
                child: widget.child,
              ))
        //除了中间弹窗,其它的都使用位移动画
        : SizeTransition(
            sizeFactor: _controller,
            child: widget.child,
          );
  }

  ///处理下内容widget动画方向
  void _dealContentAnimate() {
    AlignmentGeometry? alignment = widget.alignment;
    _offset = Offset(0, 0);

    if (alignment == Alignment.bottomCenter ||
        alignment == Alignment.bottomLeft ||
        alignment == Alignment.bottomRight) {
      //靠下
      _offset = Offset(0, 1);
    } else if (alignment == Alignment.topCenter ||
        alignment == Alignment.topLeft ||
        alignment == Alignment.topRight) {
      //靠上
      _offset = Offset(0, -1);
    } else if (alignment == Alignment.centerLeft) {
      //靠左
      _offset = Offset(-1, 0);
    } else if (alignment == Alignment.centerRight) {
      //靠右
      _offset = Offset(1, 0);
    } else {
      //居中使用缩放动画,空结构体,不需要操作
    }
  }

  ///等待动画结束,关闭动画资源
  Future<void> dismiss() async {
    //背景结束动画
    _opacity = 0.0;
    if (mounted) setState(() {});

    //内容widget结束动画
    _controller.reverse();

    if (widget.isUseAnimation) {
      await Future.delayed(widget.animationDuration);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AttachDialogController extends BaseController {
  _AttachDialogWidgetState? _state;

  void bind(_AttachDialogWidgetState _state) {
    this._state = _state;
  }

  @override
  Future<void> dismiss() async {
    await _state?.dismiss();
    _state = null;
  }
}

class SizeTransition extends AnimatedWidget {
  const SizeTransition({
    Key? key,
    this.axis = Axis.vertical,
    required Animation<double> sizeFactor,
    this.axisAlignment = 0.0,
    this.child,
  }) : super(key: key, listenable: sizeFactor);

  final Axis axis;

  Animation<double> get sizeFactor => listenable as Animation<double>;

  final double axisAlignment;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final AlignmentDirectional alignment;
    if (axis == Axis.vertical)
      alignment = AlignmentDirectional(-1.0, axisAlignment);
    else
      alignment = AlignmentDirectional(axisAlignment, -1.0);
    return ClipRect(
      child: Align(
        alignment: alignment,
        heightFactor: axis == Axis.vertical ? max(sizeFactor.value, 0.0) : null,
        widthFactor:
            axis == Axis.horizontal ? max(sizeFactor.value, 0.0) : null,
        child: child,
      ),
    );
  }
}
