import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

class YoutubeMiniVideoSreen extends StatefulWidget {
  const YoutubeMiniVideoSreen({super.key});

  @override
  State<YoutubeMiniVideoSreen> createState() => _YoutubeMiniVideoSreenState();
}

class _YoutubeMiniVideoSreenState extends State<YoutubeMiniVideoSreen> {
  final double minExtent = 0.3;
  final double maxExtent = 1.0;

  // Thêm các state cho animate duy nhất 1 video box
  double extent = 1.0;
  bool isMiniPlayer = false;
  bool isSheetVisible = false;
  int curIndexVideo = 0;

  double left = 0;
  double top = 0;

  // padding cách mép màn hình cho mini-player
  final double miniMargin = 16.0;

  // Các góc màn hình
  Offset getCorner(
    int corner,
    double miniW,
    double miniH,
    double screenW,
    double screenH,
  ) {
    switch (corner) {
      case 0: // Top-left
        return Offset(miniMargin, miniMargin);
      case 1: // Top-right
        return Offset(screenW - miniW - miniMargin, miniMargin);
      case 2: // Bottom-left
        return Offset(miniMargin, screenH - miniH - miniMargin - 80);
      case 3: // Bottom-right
        return Offset(
          screenW - miniW - miniMargin,
          screenH - miniH - miniMargin - 80,
        );
      default:
        return Offset(
          screenW - miniW - miniMargin,
          screenH - miniH - miniMargin - 80,
        );
    }
  }

  int findNearestCorner(
    double l,
    double t,
    double miniW,
    double miniH,
    double screenW,
    double screenH,
  ) {
    final corners = [
      getCorner(0, miniW, miniH, screenW, screenH),
      getCorner(1, miniW, miniH, screenW, screenH),
      getCorner(2, miniW, miniH, screenW, screenH),
      getCorner(3, miniW, miniH, screenW, screenH),
    ];
    double minDist = double.infinity;
    int res = 3;
    for (int i = 0; i < 4; ++i) {
      double dx = l - corners[i].dx;
      double dy = t - corners[i].dy;
      double d = dx * dx + dy * dy;
      if (d < minDist) {
        minDist = d;
        res = i;
      }
    }
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final screenH = media.size.height;

    // full video size (16:9)
    final fullW = screenW;
    final fullH = fullW * 9 / 16;

    // mini video size
    final miniW = 200.0;
    final miniH = miniW * 9 / 16;

    // Tính toán vị trí và size video tuỳ theo trạng thái
    double videoW = lerpDouble(miniW, fullW, extent)!;
    double videoH = lerpDouble(miniH, fullH, extent)!;
    double videoLeft = isMiniPlayer
        ? left.clamp(miniMargin, screenW - miniW - miniMargin)
        : 0.0;
    double videoTop = isMiniPlayer
        ? top.clamp(miniMargin, screenH - miniH - miniMargin - 80)
        : 0.0;

    // Nếu vừa chuyển sang mini-player thì gắn vị trí mặc định là góc dưới bên phải (có margin)
    if (isMiniPlayer && left == 0 && top == 0) {
      videoLeft = screenW - miniW - miniMargin;
      videoTop = screenH - miniH - miniMargin - 80;
      left = videoLeft;
      top = videoTop;
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      isMiniPlayer = false;
                      isSheetVisible = true;
                      extent = 1.0;
                      curIndexVideo = index;
                    });
                  },
                  child: Container(
                    height: fullH,
                    width: fullW,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      border: Border.all(width: 1),
                    ),
                    child: Center(
                      child: Text(
                        "Video ${index.toString()}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Video box duy nhất (animate vị trí + size + drag mini + snap to 4 góc)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
              left: videoLeft,
              top: videoTop,
              width: videoW,
              height: videoH,
              child: GestureDetector(
                onTap: () {
                  if (isMiniPlayer) {
                    setState(() {
                      isMiniPlayer = false;
                      isSheetVisible = true;
                      extent = 1.0;
                      // animate về center
                      left = 0;
                      top = 0;
                    });
                  }
                },
                onPanUpdate: isMiniPlayer
                    ? (details) {
                        setState(() {
                          left = (left + details.delta.dx).clamp(
                            miniMargin,
                            screenW - miniW - miniMargin,
                          );
                          // KHÔNG clamp dưới nữa để kéo xuống được
                          top = (top + details.delta.dy);
                          if (top < miniMargin) {
                            top = miniMargin; // chỉ clamp trên
                          }
                        });
                      }
                    : null,
                onPanEnd: isMiniPlayer
                    ? (details) {
                        int cornerIdx = findNearestCorner(
                          left,
                          top,
                          miniW,
                          miniH,
                          screenW,
                          screenH,
                        );
                        Offset c = getCorner(
                          cornerIdx,
                          miniW,
                          miniH,
                          screenW,
                          screenH,
                        );
                        // Nếu là góc phải dưới, kiểm tra kéo quá đáy
                        final double bottomThreshold = 40.0;
                        final double bottomEdge = screenH - miniMargin - 80;
                        if (cornerIdx == 3 &&
                            top > bottomEdge + bottomThreshold) {
                          setState(() {
                            isMiniPlayer = false;
                          });
                        } else {
                          setState(() {
                            left = c.dx;
                            top = c.dy;
                          });
                        }
                      }
                    : null,
                onDoubleTap: () {
                  if (!isMiniPlayer) {
                    setState(() {
                      isMiniPlayer = true;
                      isSheetVisible = false;
                      extent = minExtent;
                      // chuyển sang mặc định góc dưới phải
                      left = screenW - miniW;
                      top = screenH - miniH - 80;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Text(
                    "Video $curIndexVideo",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),

            // Sheet overlay (không có video nữa, chỉ dữ liệu)
            if (isSheetVisible)
              Positioned(
                left: 0,
                right: 0,
                top: videoH,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: isSheetVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    color: Colors.blueGrey,
                    child: Center(
                      child: Text(
                        "data $curIndexVideo",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),

            // Nút chuyển về mini-player nếu đang ở sheet
            if (isSheetVisible)
              Positioned(
                top: videoH + 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      isSheetVisible = false;
                      isMiniPlayer = true;
                      extent = minExtent;
                      left = screenW - miniW;
                      top = screenH - miniH - 80;
                    });
                  },
                  color: Colors.black.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
