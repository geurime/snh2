import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/strings.dart';

/// 마감을 저장한 뒤 공유 시트를 띄운다.
///
/// 대표가 카톡 단톡방으로 다시 보내라고 해서, 푸시를 받아도 직원이 같은 내용을
/// 손으로 또 친다. 알림톡은 1:1만 되고 단톡방에 못 넣어서 자동화가 불가능하다.
/// 그래서 **문구를 앱이 완성해주고 보낼 방을 직원이 고르는** 형태로 둔다.
///
/// 카카오톡을 직접 지목하지 않는다 — 공유 시트가 마지막에 보낸 방을 위에
/// 올려주므로 실제로는 두 번 누르면 끝이고, 대표가 채널을 바꿔도 코드가 안 바뀐다.
abstract final class ClosingShare {
  static Future<void> send(
    BuildContext context, {
    required DateTime date,
    required double kg,
    required int count,
  }) async {
    // iPad는 팝오버가 뜰 기준 사각형을 요구한다. 없으면 화면 밖에 그려진다.
    final box = context.findRenderObject();
    final origin = box is RenderBox && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: S.closingShare(date, kg, count),
          title: S.closingShareTitle,
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      // 공유는 실패해도 저장은 이미 끝났다. 여기서 막으면 마감이 안 끝난 것처럼 보인다.
    }
  }
}
