import 'package:flutter/material.dart';

class PinyinLearnGridCodiaPage extends StatefulWidget {
  const PinyinLearnGridCodiaPage({super.key});

  @override
  State<StatefulWidget> createState() => _PinyinLearnGridCodiaPageState();
}

class _PinyinLearnGridCodiaPageState extends State<PinyinLearnGridCodiaPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Container(
        height: 1024,
        decoration: BoxDecoration(
          color: const Color(0x00000000),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 1024,
              child: Container(
                height: 1024,
                decoration: BoxDecoration(
                  color: const Color(0x00000000),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      width: 1536,
                      bottom: 0,
                      height: 1024,
                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_canvas_bg.png', width: 1536, height: 1024, fit: BoxFit.cover,),
                    ),
                    Positioned(
                      right: 0,
                      width: 1536,
                      bottom: 1,
                      height: 855,
                      child: Container(
                        width: 1536,
                        height: 855,
                        decoration: BoxDecoration(
                          color: const Color(0x00000000),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 131,
                              width: 1290,
                              bottom: 40,
                              height: 826,
                              child: Image.asset('assets/figma_ui/figma_pinyin_grid_panel_bg.png', width: 1290, height: 826, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 0,
                              width: 1536,
                              bottom: 43,
                              height: 139,
                              child: Container(
                                width: 1536,
                                height: 139,
                                decoration: BoxDecoration(
                                  color: const Color(0x00000000),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 139,
                                      width: 1302,
                                      bottom: -6,
                                      height: 152,
                                      child: Container(
                                        width: 1302,
                                        height: 152,
                                        decoration: BoxDecoration(
                                          color: const Color(0x00000000),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              right: 7,
                                              width: 1264,
                                              bottom: 6,
                                              height: 146,
                                              child: Image.asset('assets/figma_ui/figma_pinyin_grid_stats_bar.png', width: 1264, height: 146, fit: BoxFit.cover,),
                                            ),
                                            Positioned(
                                              right: 44,
                                              width: 71,
                                              bottom: 41,
                                              height: 74,
                                              child: Image.asset('assets/figma_ui/figma_pinyin_grid_03.png', width: 71, height: 74, fit: BoxFit.cover,),
                                            ),
                                            Positioned(
                                              right: 123,
                                              width: 69,
                                              bottom: 38,
                                              height: 73,
                                              child: Container(
                                                width: 69,
                                                height: 73,
                                                decoration: BoxDecoration(
                                                  color: const Color(0x00000000),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Positioned(
                                                      right: 5,
                                                      width: 58,
                                                      bottom: 6,
                                                      height: 64,
                                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_04.png', width: 58, height: 64, fit: BoxFit.cover,),
                                                    ),
                                                    Positioned(
                                                      right: 15,
                                                      width: 33,
                                                      bottom: 25,
                                                      height: 27,
                                                      child: Text(
                                                        '50',
                                                        textAlign: TextAlign.left,
                                                        style: TextStyle(decoration: TextDecoration.none, fontSize: 24, color: const Color(0xfff4f6f7), fontWeight: FontWeight.normal),
                                                        maxLines: 9999,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 198,
                                              width: 25,
                                              bottom: 69,
                                              height: 11,
                                              child: Image.asset('assets/figma_ui/figma_pinyin_grid_05.png', width: 25, height: 11, fit: BoxFit.cover,),
                                            ),
                                            Positioned(
                                              right: 227,
                                              width: 65,
                                              bottom: 38,
                                              height: 73,
                                              child: Container(
                                                width: 65,
                                                height: 73,
                                                decoration: BoxDecoration(
                                                  color: const Color(0x00000000),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Positioned(
                                                      right: 1,
                                                      width: 59,
                                                      bottom: 6,
                                                      height: 64,
                                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_06.png', width: 59, height: 64, fit: BoxFit.cover,),
                                                    ),
                                                    Positioned(
                                                      right: 11,
                                                      width: 34,
                                                      bottom: 24,
                                                      height: 28,
                                                      child: Text(
                                                        '40',
                                                        textAlign: TextAlign.left,
                                                        style: TextStyle(decoration: TextDecoration.none, fontSize: 25, color: const Color(0xfff4f5f7), fontWeight: FontWeight.normal),
                                                        maxLines: 9999,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 293,
                                              width: 39,
                                              bottom: 69,
                                              height: 12,
                                              child: Image.asset('assets/figma_ui/figma_pinyin_grid_07.png', width: 39, height: 12, fit: BoxFit.cover,),
                                            ),
                                            Positioned(
                                              right: 336,
                                              width: 65,
                                              bottom: 38,
                                              height: 73,
                                              child: Container(
                                                width: 65,
                                                height: 73,
                                                decoration: BoxDecoration(
                                                  color: const Color(0x00000000),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Positioned(
                                                      right: 1,
                                                      width: 59,
                                                      bottom: 6,
                                                      height: 64,
                                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_08.png', width: 59, height: 64, fit: BoxFit.cover,),
                                                    ),
                                                    Positioned(
                                                      right: 11,
                                                      width: 37,
                                                      bottom: 24,
                                                      height: 28,
                                                      child: Text(
                                                        '30',
                                                        textAlign: TextAlign.left,
                                                        style: TextStyle(decoration: TextDecoration.none, fontSize: 27, color: const Color(0xfff3f5f7), fontWeight: FontWeight.normal),
                                                        maxLines: 9999,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 402,
                                              width: 40,
                                              bottom: 69,
                                              height: 12,
                                              child: Image.asset('assets/figma_ui/figma_pinyin_grid_09.png', width: 40, height: 12, fit: BoxFit.cover,),
                                            ),
                                            Positioned(
                                              right: 445,
                                              width: 67,
                                              bottom: 38,
                                              height: 73,
                                              child: Container(
                                                width: 67,
                                                height: 73,
                                                decoration: BoxDecoration(
                                                  color: const Color(0x00000000),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Positioned(
                                                      right: 2,
                                                      width: 59,
                                                      bottom: 6,
                                                      height: 64,
                                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_10.png', width: 59, height: 64, fit: BoxFit.cover,),
                                                    ),
                                                    Positioned(
                                                      right: 11,
                                                      width: 36,
                                                      bottom: 23,
                                                      height: 29,
                                                      child: Text(
                                                        '20',
                                                        textAlign: TextAlign.left,
                                                        style: TextStyle(decoration: TextDecoration.none, fontSize: 27, color: const Color(0xfff5f6f7), fontWeight: FontWeight.normal),
                                                        maxLines: 9999,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 514,
                                              width: 42,
                                              bottom: 70,
                                              height: 11,
                                              child: Image.asset('assets/figma_ui/figma_pinyin_grid_11.png', width: 42, height: 11, fit: BoxFit.cover,),
                                            ),
                                            Positioned(
                                              right: 562,
                                              width: 82,
                                              bottom: 37,
                                              height: 82,
                                              child: Image.asset('assets/figma_ui/figma_pinyin_grid_12.png', width: 82, height: 82, fit: BoxFit.cover,),
                                            ),
                                            Positioned(
                                              right: 731,
                                              width: 389,
                                              bottom: 28,
                                              height: 91,
                                              child: Container(
                                                width: 389,
                                                height: 91,
                                                decoration: BoxDecoration(
                                                  color: const Color(0x00000000),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    Positioned(
                                                      right: 6,
                                                      width: 377,
                                                      bottom: 4,
                                                      height: 84,
                                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_13.png', width: 377, height: 84, fit: BoxFit.cover,),
                                                    ),
                                                    Positioned(
                                                      right: 315,
                                                      width: 45,
                                                      bottom: 28,
                                                      height: 42,
                                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_14.png', width: 45, height: 42, fit: BoxFit.cover,),
                                                    ),
                                                    Positioned(
                                                      right: 44,
                                                      width: 254,
                                                      bottom: 28,
                                                      height: 36,
                                                      child: Text(
                                                        '小朋友，继续加油哦!',
                                                        textAlign: TextAlign.left,
                                                        style: TextStyle(decoration: TextDecoration.none, fontSize: 27, color: const Color(0xff4b6c9f), fontWeight: FontWeight.normal),
                                                        maxLines: 9999,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 1271,
                              width: 166,
                              bottom: 45,
                              height: 155,
                              child: Image.asset('assets/figma_ui/figma_pinyin_grid_mascot_panda.png', width: 166, height: 155, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 12,
                              width: 120,
                              bottom: 328,
                              height: 145,
                              child: Image.asset('assets/figma_ui/figma_pinyin_grid_side_deco.png', width: 120, height: 145, fit: BoxFit.cover,),
                            ),
                            Positioned(
                              right: 164,
                              width: 292,
                              bottom: 217,
                              height: 305,
                              child: Container(
                                width: 292,
                                height: 305,
                                decoration: BoxDecoration(
                                  color: const Color(0x00000000),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 6,
                                      width: 279,
                                      bottom: 7,
                                      height: 293,
                                      child: Container(
                                        width: 279,
                                        height: 293,
                                        decoration: BoxDecoration(
                                          color: const Color(0xfffbfaf8),
                                          borderRadius: BorderRadius.circular(37),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 29,
                                      width: 233,
                                      bottom: 16,
                                      height: 10,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_17.png', width: 233, height: 10, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 27,
                                      width: 118,
                                      bottom: 36,
                                      height: 91,
                                      child: Container(
                                        width: 118,
                                        height: 91,
                                        decoration: BoxDecoration(
                                          color: const Color(0x00000000),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              right: 4,
                                              width: 108,
                                              bottom: 4,
                                              height: 81,
                                              child: Container(
                                                width: 108,
                                                height: 81,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xfffefefd),
                                                  border: Border.all(color: const Color(0xffddcbb9), width: 1),
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 38,
                                              width: 39,
                                              bottom: 10,
                                              child: Text(
                                                'カ',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 36, color: const Color(0xff5e5c5c), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Positioned(
                                              right: 48,
                                              width: 16,
                                              bottom: 55,
                                              height: 23,
                                              child: Text(
                                                'li',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 21, color: const Color(0xff636263), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 175,
                                      width: 87,
                                      bottom: 43,
                                      height: 87,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_18.png', width: 87, height: 87, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 31,
                                      width: 128,
                                      bottom: 136,
                                      height: 138,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_19.png', width: 128, height: 138, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 212,
                                      width: 24,
                                      bottom: 169,
                                      height: 107,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_20.png', width: 24, height: 107, fit: BoxFit.cover,),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 469,
                              width: 293,
                              bottom: 217,
                              height: 305,
                              child: Container(
                                width: 293,
                                height: 305,
                                decoration: BoxDecoration(
                                  color: const Color(0x00000000),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 7,
                                      width: 279,
                                      bottom: 7,
                                      height: 293,
                                      child: Container(
                                        width: 279,
                                        height: 293,
                                        decoration: BoxDecoration(
                                          color: const Color(0xfffaf9f8),
                                          borderRadius: BorderRadius.circular(37),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 31,
                                      width: 232,
                                      bottom: 16,
                                      height: 10,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_21.png', width: 232, height: 10, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 28,
                                      width: 118,
                                      bottom: 37,
                                      height: 90,
                                      child: Container(
                                        width: 118,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          color: const Color(0x00000000),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              right: 4,
                                              width: 109,
                                              bottom: 4,
                                              height: 81,
                                              child: Container(
                                                width: 109,
                                                height: 81,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xfffefefd),
                                                  border: Border.all(color: const Color(0xffd9ccba), width: 1),
                                                  borderRadius: BorderRadius.circular(13.5),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 35,
                                              width: 43,
                                              bottom: 12,
                                              height: 41,
                                              child: Text(
                                                '泥',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 33, color: const Color(0xff5b595a), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Positioned(
                                              right: 45,
                                              width: 23,
                                              bottom: 54,
                                              height: 22,
                                              child: Text(
                                                'ní',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 20, color: const Color(0xff838284), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 176,
                                      width: 87,
                                      bottom: 43,
                                      height: 87,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_22.png', width: 87, height: 87, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 31,
                                      width: 127,
                                      bottom: 140,
                                      height: 117,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_23.png', width: 127, height: 117, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 186,
                                      width: 70,
                                      bottom: 177,
                                      height: 78,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_24.png', width: 70, height: 78, fit: BoxFit.cover,),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 775,
                              width: 284,
                              bottom: 217,
                              height: 301,
                              child: Container(
                                width: 284,
                                height: 301,
                                decoration: BoxDecoration(
                                  color: const Color(0x00000000),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 4,
                                      width: 279,
                                      bottom: 7,
                                      height: 293,
                                      child: Container(
                                        width: 279,
                                        height: 293,
                                        decoration: BoxDecoration(
                                          color: const Color(0xfffbfaf8),
                                          borderRadius: BorderRadius.circular(36),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 26,
                                      width: 234,
                                      bottom: 17,
                                      height: 9,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_25.png', width: 234, height: 9, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 22,
                                      width: 119,
                                      bottom: 37,
                                      height: 91,
                                      child: Container(
                                        width: 119,
                                        height: 91,
                                        decoration: BoxDecoration(
                                          color: const Color(0x00000000),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              right: 4,
                                              width: 110,
                                              bottom: 4,
                                              height: 82,
                                              child: Container(
                                                width: 110,
                                                height: 82,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xfffefefe),
                                                  border: Border.all(color: const Color(0xffdcccba), width: 1),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 35,
                                              width: 44,
                                              bottom: 14,
                                              height: 39,
                                              child: Text(
                                                '土',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 34, color: const Color(0xff636262), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Positioned(
                                              right: 46,
                                              width: 24,
                                              bottom: 54,
                                              height: 22,
                                              child: Text(
                                                'tu',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 23, color: const Color(0xff747374), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 173,
                                      width: 87,
                                      bottom: 43,
                                      height: 87,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_26.png', width: 87, height: 87, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 26,
                                      width: 127,
                                      bottom: 140,
                                      height: 134,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_27.png', width: 127, height: 134, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 187,
                                      width: 59,
                                      bottom: 169,
                                      height: 104,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_28.png', width: 59, height: 104, fit: BoxFit.cover,),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 1083,
                              width: 290,
                              bottom: 216,
                              height: 301,
                              child: Container(
                                width: 290,
                                height: 301,
                                decoration: BoxDecoration(
                                  color: const Color(0x00000000),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 1,
                                      width: 279,
                                      bottom: 8,
                                      height: 294,
                                      child: Container(
                                        width: 279,
                                        height: 294,
                                        decoration: BoxDecoration(
                                          color: const Color(0xfffafaf8),
                                          borderRadius: BorderRadius.circular(35),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 24,
                                      width: 235,
                                      bottom: 18,
                                      height: 10,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_29.png', width: 235, height: 10, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 20,
                                      width: 118,
                                      bottom: 39,
                                      height: 89,
                                      child: Container(
                                        width: 118,
                                        height: 89,
                                        decoration: BoxDecoration(
                                          color: const Color(0x00000000),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              right: 4,
                                              width: 109,
                                              bottom: 4,
                                              height: 81,
                                              child: Container(
                                                width: 109,
                                                height: 81,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xfffefefe),
                                                  border: Border.all(color: const Color(0xffdbccbb), width: 1),
                                                  borderRadius: BorderRadius.circular(14.25),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 36,
                                              width: 42,
                                              bottom: 12,
                                              height: 41,
                                              child: Text(
                                                '大',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 35, color: const Color(0xff5a585a), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Positioned(
                                              right: 44,
                                              width: 28,
                                              bottom: 53,
                                              height: 23,
                                              child: Text(
                                                'dà',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 21, color: const Color(0xff757576), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 172,
                                      width: 84,
                                      bottom: 45,
                                      height: 87,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_30.png', width: 84, height: 87, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 12,
                                      width: 134,
                                      bottom: 137,
                                      height: 140,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_31.png', width: 134, height: 140, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 173,
                                      width: 84,
                                      bottom: 167,
                                      height: 119,
                                      child: Text(
                                        'd',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(decoration: TextDecoration.none, fontSize: 130, color: const Color(0xff214b8c), fontWeight: FontWeight.normal),
                                        maxLines: 9999,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 164,
                              width: 291,
                              bottom: 529,
                              height: 312,
                              child: Container(
                                width: 291,
                                height: 312,
                                decoration: BoxDecoration(
                                  color: const Color(0x00000000),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 6,
                                      width: 278,
                                      bottom: 2,
                                      height: 299,
                                      child: Container(
                                        width: 278,
                                        height: 299,
                                        decoration: BoxDecoration(
                                          color: const Color(0xfffafaf8),
                                          borderRadius: BorderRadius.circular(35),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 28,
                                      width: 234,
                                      bottom: 10,
                                      height: 10,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_32.png', width: 234, height: 10, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 28,
                                      width: 116,
                                      bottom: 31,
                                      height: 84,
                                      child: Container(
                                        width: 116,
                                        height: 84,
                                        decoration: BoxDecoration(
                                          color: const Color(0x00000000),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              right: 3,
                                              width: 108,
                                              bottom: 3,
                                              height: 80,
                                              child: Container(
                                                width: 108,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xfffefdfc),
                                                  border: Border.all(color: const Color(0xffd9cec1), width: 1),
                                                  borderRadius: BorderRadius.circular(12.75),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 36,
                                              width: 43,
                                              bottom: 8,
                                              height: 44,
                                              child: Text(
                                                '佛',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 40, color: const Color(0xff6d6c6c), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Positioned(
                                              right: 44,
                                              width: 25,
                                              bottom: 53,
                                              height: 23,
                                              child: Text(
                                                'fó',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 21, color: const Color(0xff7a7a7b), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 174,
                                      width: 87,
                                      bottom: 37,
                                      height: 87,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_33.png', width: 87, height: 87, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 34,
                                      width: 113,
                                      bottom: 117,
                                      height: 159,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_34.png', width: 113, height: 159, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 190,
                                      width: 58,
                                      bottom: 171,
                                      height: 108,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_35.png', width: 58, height: 108, fit: BoxFit.cover,),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 469,
                              width: 293,
                              bottom: 529,
                              height: 312,
                              child: Container(
                                width: 293,
                                height: 312,
                                decoration: BoxDecoration(
                                  color: const Color(0x00000000),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 7,
                                      width: 278,
                                      bottom: 3,
                                      height: 298,
                                      child: Container(
                                        width: 278,
                                        height: 298,
                                        decoration: BoxDecoration(
                                          color: const Color(0xfffafaf8),
                                          borderRadius: BorderRadius.circular(33),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 30,
                                      width: 232,
                                      bottom: 11,
                                      height: 9,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_36.png', width: 232, height: 9, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 28,
                                      width: 118,
                                      bottom: 31,
                                      height: 90,
                                      child: Container(
                                        width: 118,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          color: const Color(0x00000000),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              right: 4,
                                              width: 108,
                                              bottom: 4,
                                              height: 80,
                                              child: Container(
                                                width: 108,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xfffefefe),
                                                  border: Border.all(color: const Color(0xffd5c7b7), width: 1),
                                                  borderRadius: BorderRadius.circular(13.5),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 34,
                                              width: 45,
                                              bottom: 10,
                                              height: 42,
                                              child: Text(
                                                '妈',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 36, color: const Color(0xff5c5b5c), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Positioned(
                                              right: 39,
                                              width: 33,
                                              bottom: 52,
                                              height: 23,
                                              child: Text(
                                                'mā',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 20, color: const Color(0xff737274), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 175,
                                      width: 87,
                                      bottom: 38,
                                      height: 87,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_37.png', width: 87, height: 87, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 16,
                                      width: 139,
                                      bottom: 143,
                                      height: 106,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_38.png', width: 139, height: 106, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 162,
                                      width: 97,
                                      bottom: 178,
                                      height: 78,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_39.png', width: 97, height: 78, fit: BoxFit.cover,),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 778,
                              width: 286,
                              bottom: 531,
                              height: 308,
                              child: Container(
                                width: 286,
                                height: 308,
                                decoration: BoxDecoration(
                                  color: const Color(0x00000000),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 0,
                                      width: 280,
                                      bottom: 0,
                                      height: 300,
                                      child: Container(
                                        width: 280,
                                        height: 300,
                                        decoration: BoxDecoration(
                                          color: const Color(0xfffaf9f8),
                                          borderRadius: BorderRadius.circular(36),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 23,
                                      width: 233,
                                      bottom: 9,
                                      height: 10,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_40.png', width: 233, height: 10, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 19,
                                      width: 117,
                                      bottom: 31,
                                      height: 85,
                                      child: Container(
                                        width: 117,
                                        height: 85,
                                        decoration: BoxDecoration(
                                          color: const Color(0x00000000),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              right: 3,
                                              width: 109,
                                              bottom: 3,
                                              height: 80,
                                              child: Container(
                                                width: 109,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xfffefdfd),
                                                  border: Border.all(color: const Color(0xffd8cdbe), width: 1),
                                                  borderRadius: BorderRadius.circular(13.5),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 37,
                                              width: 42,
                                              bottom: 8,
                                              height: 43,
                                              child: Text(
                                                '婆',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 40, color: const Color(0xff6f6e6e), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Positioned(
                                              right: 42,
                                              width: 28,
                                              bottom: 51,
                                              height: 23,
                                              child: Text(
                                                'pó',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 20, color: const Color(0xff6f6e6f), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 170,
                                      width: 83,
                                      bottom: 36,
                                      height: 86,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_41.png', width: 83, height: 86, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 21,
                                      width: 112,
                                      bottom: 122,
                                      height: 151,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_42.png', width: 112, height: 151, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 161,
                                      width: 83,
                                      bottom: 141,
                                      height: 123,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_43.png', width: 83, height: 123, fit: BoxFit.cover,),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              right: 1081,
                              width: 289,
                              bottom: 530,
                              height: 311,
                              child: Container(
                                width: 289,
                                height: 311,
                                decoration: BoxDecoration(
                                  color: const Color(0x00000000),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 3,
                                      width: 278,
                                      bottom: 3,
                                      height: 298,
                                      child: Container(
                                        width: 278,
                                        height: 298,
                                        decoration: BoxDecoration(
                                          color: const Color(0xfffaf9f8),
                                          borderRadius: BorderRadius.circular(32),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 24,
                                      width: 235,
                                      bottom: 11,
                                      height: 10,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_44.png', width: 235, height: 10, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 20,
                                      width: 119,
                                      bottom: 32,
                                      height: 89,
                                      child: Container(
                                        width: 119,
                                        height: 89,
                                        decoration: BoxDecoration(
                                          color: const Color(0x00000000),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              right: 3,
                                              width: 111,
                                              bottom: 3,
                                              height: 80,
                                              child: Container(
                                                width: 111,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xfffefefe),
                                                  border: Border.all(color: const Color(0xffd7cbbd), width: 1),
                                                  borderRadius: BorderRadius.circular(15),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 32,
                                              width: 45,
                                              bottom: 14,
                                              child: Text(
                                                'bā\n八',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 31, color: const Color(0xff5c5b5c), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 171,
                                      width: 87,
                                      bottom: 38,
                                      height: 87,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_45.png', width: 87, height: 87, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 18,
                                      width: 126,
                                      bottom: 127,
                                      height: 130,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_46.png', width: 126, height: 130, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 161,
                                      width: 85,
                                      bottom: 163,
                                      height: 123,
                                      child: Text(
                                        'b',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(decoration: TextDecoration.none, fontSize: 130, color: const Color(0xff234c8c), fontWeight: FontWeight.normal),
                                        maxLines: 9999,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      width: 1536,
                      bottom: 142,
                      height: 882,
                      child: Container(
                        width: 1536,
                        height: 882,
                        decoration: BoxDecoration(
                          color: const Color(0x00000000),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 0,
                              width: 1536,
                              bottom: 724,
                              height: 158,
                              child: Container(
                                width: 1536,
                                height: 158,
                                decoration: BoxDecoration(
                                  color: const Color(0x00000000),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: 27,
                                      width: 123,
                                      bottom: 19,
                                      height: 123,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_47.png', width: 123, height: 123, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 295,
                                      width: 147,
                                      bottom: 50,
                                      height: 74,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_48.png', width: 147, height: 74, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 551,
                                      width: 216,
                                      bottom: 8,
                                      height: 88,
                                      child: Container(
                                        width: 216,
                                        height: 88,
                                        decoration: BoxDecoration(
                                          color: const Color(0x00000000),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              right: 3,
                                              width: 209,
                                              bottom: 2,
                                              height: 80,
                                              child: Container(
                                                width: 209,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xffeae9e9),
                                                  border: Border.all(color: const Color(0xffd8dddf), width: 1),
                                                  borderRadius: BorderRadius.circular(37),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 68,
                                              width: 77,
                                              bottom: 23,
                                              height: 41,
                                              child: Text(
                                                '韵母',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 33, color: const Color(0xff828283), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 771,
                                      width: 222,
                                      bottom: 10,
                                      height: 86,
                                      child: Container(
                                        width: 222,
                                        height: 86,
                                        decoration: BoxDecoration(
                                          color: const Color(0x00000000),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              right: 2,
                                              width: 214,
                                              bottom: 2,
                                              height: 78,
                                              child: Container(
                                                width: 214,
                                                height: 78,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xff0baeb9),
                                                  border: Border.all(color: const Color(0xffc1e5e7), width: 4),
                                                  borderRadius: BorderRadius.circular(35),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 68,
                                              width: 79,
                                              bottom: 22,
                                              child: Text(
                                                '声母',
                                                textAlign: TextAlign.left,
                                                style: TextStyle(decoration: TextDecoration.none, fontSize: 34, color: const Color(0xffd4eeee), fontWeight: FontWeight.normal),
                                                maxLines: 9999,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 1083,
                                      width: 62,
                                      bottom: 39,
                                      height: 44,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_back_btn.png', width: 62, height: 44, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 1232,
                                      width: 171,
                                      bottom: 47,
                                      height: 99,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_title_deco.png', width: 171, height: 99, fit: BoxFit.cover,),
                                    ),
                                    Positioned(
                                      right: 1407,
                                      width: 87,
                                      bottom: 35,
                                      height: 90,
                                      child: Image.asset('assets/figma_ui/figma_pinyin_grid_avatar.png', width: 87, height: 90, fit: BoxFit.cover,),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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