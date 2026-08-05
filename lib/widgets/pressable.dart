import 'package:flutter/material.dart';
import '../constants/spacing.dart';

/// 누르면 살짝 줄어드는 터치 피드백.
///
/// 잉크 물결(InkWell) 대신 축소를 쓰는 이유:
/// - 물결은 요소 밖으로 퍼져서 우리가 만든 조용한 톤과 안 맞는다
/// - 카드·행·토글처럼 모양이 제각각인 것들에 일관되게 얹힌다
///
/// 특히 서버 왕복이 있는 조작(충전기 토글 등)에 필요하다 — 저장이 끝나야 화면이
/// 바뀌는데 그동안 아무 반응이 없으면 눌린 줄 모르고 또 누른다.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// 눌렸을 때 배율. 면적이 큰 요소일수록 덜 줄여야 자연스럽다.
  final double scale;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: AppMotion.of(context, AppMotion.fast),
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}
