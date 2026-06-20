import 'package:flutter/material.dart';

class PinyinLearnDetailCodiaPage extends StatefulWidget {
  const PinyinLearnDetailCodiaPage({super.key});

  @override
  State<StatefulWidget> createState() => _PinyinLearnDetailCodiaPageState();
}

class _PinyinLearnDetailCodiaPageState extends State<PinyinLearnDetailCodiaPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Container(
        height: 1164,
        decoration: BoxDecoration(
          color: const Color(0x00000000),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1164,
              child: Container(
                height: 1164,
                decoration: BoxDecoration(
                  color: const Color(0xfffbfbfa),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 1164,
                      child: Image.asset('assets/figma_ui/figma_pinyin_detail_modal_bg.png', height: 1164,),
                    ),
                    Positioned(
                      right: 2292,
                      width: 32,
                      bottom: 0,
                      height: 1164,
                      child: Image.asset('assets/figma_ui/figma_pinyin_detail_01.png', width: 32, height: 1164, fit: BoxFit.cover,),
                    ),
                    Positioned(
                      right: 0,
                      width: 11,
                      bottom: 0,
                      height: 1164,
                      child: Image.asset('assets/figma_ui/figma_pinyin_detail_02.png', width: 11, height: 1164, fit: BoxFit.cover,),
                    ),
                    Positioned(
                      right: 47,
                      width: 329,
                      bottom: 139,
                      height: 778,
                      child: Image.asset('assets/figma_ui/figma_pinyin_detail_right_illustration.png', width: 329, height: 778, fit: BoxFit.cover,),
                    ),
                    Positioned(
                      right: 379,
                      width: 546,
                      bottom: 145,
                      height: 418,
                      child: Container(
                        width: 546,
                        height: 418,
                        decoration: BoxDecoration(
                          color: const Color(0x00000000),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 3,
                              width: 535,
                              bottom: 22,
                              height: 391,
                              child: Container(
                                width: 535,
                                height: 391,
                                decoration: BoxDecoration(
                                  color: const Color(0xfffbfaf9),
                                  border: Border.all(color: const Color(0xffeeeded), width: 2),
                                  borderRadius: BorderRadius.circular(37),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 13,
                              width: 275,
                              bottom: 17,
                              height: 302,
                              child: Image.asset('assets/figma_ui/figma_pinyin_detail_04.png', width: 275, height: 302, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 226,
                              width: 46,
                              bottom: 160,
                              height: 52,
                              child: Image.asset('assets/figma_ui/figma_pinyin_detail_05.png', width: 46, height: 52, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 251,
                              width: 40,
                              bottom: 312,
                              height: 48,
                              child: Image.asset('assets/figma_ui/figma_pinyin_detail_06.png', width: 40, height: 48, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 325,
                              width: 41,
                              bottom: 322,
                              height: 23,
                              child: Image.asset('assets/figma_ui/figma_pinyin_detail_07.png', width: 41, height: 23, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 352,
                              width: 127,
                              bottom: 100,
                              height: 57,
                              child: Text(
                                'báisè',
                                textAlign: TextAlign.left,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 49, color: const Color(0xff69ba7d), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Positioned(
                              right: 323,
                              width: 158,
                              bottom: 179,
                              height: 88,
                              child: Text(
                                '白色',
                                textAlign: TextAlign.left,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 75, color: const Color(0xff616161), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Positioned(
                              right: 390,
                              width: 100,
                              bottom: 309,
                              height: 58,
                              child: Text(
                                'b·ái',
                                textAlign: TextAlign.left,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 56, color: const Color(0xff68ba7a), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2297,
                      width: 26,
                      bottom: 275,
                      height: 53,
                      child: Image.asset('assets/figma_ui/figma_pinyin_detail_08.png', width: 26, height: 53, fit: BoxFit.cover,),
                    ),
                    Positioned(
                      right: 381,
                      width: 539,
                      bottom: 580,
                      height: 373,
                      child: Container(
                        width: 539,
                        height: 373,
                        decoration: BoxDecoration(
                          color: const Color(0x00000000),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 1,
                              width: 535,
                              bottom: 5,
                              height: 366,
                              child: Container(
                                width: 535,
                                height: 366,
                                decoration: BoxDecoration(
                                  color: const Color(0xfffbfaf9),
                                  border: Border.all(color: const Color(0xffecebea), width: 3),
                                  borderRadius: BorderRadius.circular(37),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 1,
                              width: 268,
                              bottom: 4,
                              height: 323,
                              child: Image.asset('assets/figma_ui/figma_pinyin_detail_09.png', width: 268, height: 323, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 323,
                              width: 40,
                              bottom: 276,
                              height: 22,
                              child: Image.asset('assets/figma_ui/figma_pinyin_detail_10.png', width: 40, height: 22, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 350,
                              width: 123,
                              bottom: 60,
                              height: 55,
                              child: Text(
                                'bàba',
                                textAlign: TextAlign.left,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 51, color: const Color(0xfff8718d), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Positioned(
                              right: 241,
                              width: 58,
                              bottom: 256,
                              height: 66,
                              child: Text(
                                '爸',
                                textAlign: TextAlign.left,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 55, color: const Color(0xff6c6b6b), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Positioned(
                              right: 314,
                              width: 166,
                              bottom: 132,
                              height: 89,
                              child: Text(
                                '爸爸',
                                textAlign: TextAlign.left,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 81, color: const Color(0xff605f5f), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Positioned(
                              right: 386,
                              width: 90,
                              bottom: 262,
                              height: 59,
                              child: Text(
                                'b·à',
                                textAlign: TextAlign.left,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 56, color: const Color(0xfff56e8d), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 948,
                      width: 675,
                      bottom: 157,
                      height: 933,
                      child: Container(
                        width: 675,
                        height: 933,
                        decoration: BoxDecoration(
                          color: const Color(0x00000000),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 8,
                              width: 662,
                              bottom: 10,
                              height: 783,
                              child: Container(
                                width: 662,
                                height: 783,
                                decoration: BoxDecoration(
                                  color: const Color(0xfffbfaf9),
                                  border: Border.all(color: const Color(0xffefeeee), width: 2),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 30,
                              width: 627,
                              bottom: 230,
                              height: 508,
                              child: Container(
                                width: 627,
                                height: 508,
                                decoration: BoxDecoration(
                                  color: const Color(0xfffbfaf9),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 31,
                              width: 617,
                              bottom: 244,
                              height: 11,
                              child: Image.asset('assets/figma_ui/figma_pinyin_detail_11.png', width: 617, height: 11, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 30,
                              width: 617,
                              bottom: 693,
                              height: 5,
                              child: Image.asset('assets/figma_ui/figma_pinyin_detail_12.png', width: 617, height: 5, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 30,
                              width: 617,
                              bottom: 415,
                              height: 7,
                              child: Image.asset('assets/figma_ui/figma_pinyin_detail_13.png', width: 617, height: 7, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 30,
                              width: 617,
                              bottom: 524,
                              height: 11,
                              child: Image.asset('assets/figma_ui/figma_pinyin_detail_14.png', width: 617, height: 11, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 334,
                              width: 4,
                              bottom: 208,
                              height: 530,
                              child: Image.asset('assets/figma_ui/figma_pinyin_detail_15.png', width: 4, height: 530, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 72,
                              width: 532,
                              bottom: 74,
                              height: 77,
                              child: Text(
                                '爸爸抱宝宝，bbb',
                                textAlign: TextAlign.left,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 67, color: const Color(0xff747374), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Positioned(
                              right: 96,
                              width: 155,
                              bottom: 278,
                              height: 118,
                              child: Text(
                                'bà',
                                textAlign: TextAlign.left,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 129, color: const Color(0xfff5587a), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Positioned(
                              right: 406,
                              width: 156,
                              bottom: 278,
                              height: 118,
                              child: Text(
                                'b',
                                textAlign: TextAlign.left,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 141, color: const Color(0xfffb7c20), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Positioned(
                              right: 94,
                              width: 156,
                              bottom: 557,
                              height: 119,
                              child: Text(
                                'bá',
                                textAlign: TextAlign.left,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 130, color: const Color(0xff3588f1), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Positioned(
                              right: 407,
                              width: 155,
                              bottom: 557,
                              height: 118,
                              child: Text(
                                'bā',
                                textAlign: TextAlign.left,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 129, color: const Color(0xff49a937), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Positioned(
                              right: 70,
                              width: 258,
                              bottom: 828,
                              height: 93,
                              child: Text(
                                '声母b',
                                textAlign: TextAlign.left,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 91, color: const Color(0xff2c4a6d), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 1650,
                      width: 597,
                      bottom: 149,
                      height: 822,
                      child: Container(
                        width: 597,
                        height: 822,
                        decoration: BoxDecoration(
                          color: const Color(0x00000000),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 5,
                              width: 586,
                              bottom: 4,
                              height: 812,
                              child: Container(
                                width: 586,
                                height: 812,
                                decoration: BoxDecoration(
                                  color: const Color(0xffedf5ee),
                                  border: Border.all(color: const Color(0xffe2eae3), width: 3),
                                  borderRadius: BorderRadius.circular(44),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 205,
                              width: 179,
                              bottom: 40,
                              height: 179,
                              child: Image.asset('assets/figma_ui/figma_pinyin_detail_letter_panel.png', width: 179, height: 179, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 102,
                              width: 310,
                              bottom: 259,
                              height: 462,
                              child: Image.asset('assets/figma_ui/figma_pinyin_detail_letter_stroke.png', width: 310, height: 462, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 338,
                              width: 56,
                              bottom: 645,
                              height: 57,
                              child: Container(
                                width: 56,
                                height: 57,
                                decoration: BoxDecoration(
                                  color: const Color(0x00000000),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 5,
                                      width: 44,
                                      bottom: 6,
                                      height: 45,
                                      child: Container(
                                        width: 44,
                                        height: 45,
                                        decoration: BoxDecoration(
                                          color: const Color(0xff52ba6f),
                                          border: Border.all(color: const Color(0xff438c69), width: 1),
                                          borderRadius: BorderRadius.circular(22),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 17,
                                      width: 21,
                                      bottom: 10,
                                      height: 36,
                                      child: Text(
                                        '1',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(decoration: TextDecoration.none, fontSize: 41, color: const Color(0xffcbe9d1), fontWeight: FontWeight.normal),
                                        maxLines: 9999,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 498,
                              width: 59,
                              bottom: 727,
                              height: 59,
                              child: Image.asset('assets/figma_ui/figma_pinyin_detail_learned_badge.png', width: 59, height: 59, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 317,
                              width: 24,
                              bottom: 468,
                              height: 33,
                              child: Text(
                                '2',
                                textAlign: TextAlign.center,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 37, color: const Color(0xffc5e6ce), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Positioned(
                              right: 376,
                              width: 103,
                              bottom: 735,
                              height: 48,
                              child: Text(
                                '已学习',
                                textAlign: TextAlign.left,
                                style: TextStyle(decoration: TextDecoration.none, fontSize: 33, color: const Color(0xff5db574), fontWeight: FontWeight.normal),
                                maxLines: 9999,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 50,
                      width: 113,
                      bottom: 1004,
                      height: 115,
                      child: Image.asset('assets/figma_ui/figma_pinyin_detail_close_btn.png', width: 113, height: 115, fit: BoxFit.cover,),
                    ),
                    Positioned(
                      right: 1067,
                      width: 170,
                      bottom: 1111,
                      height: 20,
                      child: Container(
                        width: 170,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xffd5d4d3),
                          border: Border.all(color: const Color(0xffdcdcdb), width: 1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      width: 2324,
                      bottom: 1161,
                      height: 3,
                      child: Image.asset('assets/figma_ui/figma_pinyin_detail_drag_handle.png', width: 2324, height: 3, fit: BoxFit.cover,),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}