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

  double extent = 1.0;
  bool isMiniPlayer = false;
  bool isSheetVisible = false;
  late int curIndexVideo;

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

    double leftMini = screenW - miniW;
    double topMini = screenH - miniH - 80;

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
                      curIndexVideo = index;
                      isSheetVisible = true;
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

            if (isMiniPlayer)
              StatefulBuilder(
                builder: (context, StateSetter stateSetter) => Positioned(
                  left: leftMini,
                  top: topMini,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isMiniPlayer = false;
                        isSheetVisible = true;
                      });
                    },
                    onPanUpdate: (details) {
                      stateSetter(() {
                        leftMini += details.delta.dx;
                        topMini += details.delta.dy;
                      });
                    },
                    onPanEnd: (details) {
                      if (topMini + miniH / 2 > screenH - miniH / 2 - 10) {
                        setState(() {
                          isMiniPlayer = false;
                        });
                        // print("close");
                      }
                      leftMini = leftMini + miniW / 2 > screenW / 2
                          ? screenW - miniW
                          : 0;
                      topMini = topMini + miniH / 2 > screenH / 2
                          ? screenH - miniH - 80
                          : 0;
                      stateSetter(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.linear,
                      width: miniW,
                      height: miniH,
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: Text(
                        "Video $curIndexVideo",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),

            if (isSheetVisible) _buildDraggableSheet(fullW, fullH),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableSheet(double fullW, double fullH) {
    double opacity = 1.0;
    double curW = fullW;
    double curH = fullH;
    final GlobalKey redBoxKey = GlobalKey();
    Offset offset = Offset.zero;

    return StatefulBuilder(
      builder: (context, StateSetter stateSetter) =>
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              double extent = notification.extent;
              double t = ((extent - minExtent) / (maxExtent - minExtent)).clamp(
                0.0,
                1.0,
              );

              stateSetter(() {
                curW = lerpDouble(200, fullW, t)!;
                curH = lerpDouble(200 * 9 / 16, fullH, t)!;
              });

              offset =
                  (redBoxKey.currentContext?.findRenderObject() as RenderBox?)!
                      .localToGlobal(Offset.zero);
              if (offset.dy > 60) {
                opacity = 0;
              } else {
                opacity = t * t * t;
              }
              return true;
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollEndNotification &&
                    offset.dy > 60) {
                  setState(() {
                    isSheetVisible = false;
                    isMiniPlayer = true;
                  });
                }
                return false;
              },
              child: DraggableScrollableSheet(
                initialChildSize: extent,
                minChildSize: minExtent,
                maxChildSize: maxExtent,
                builder: (context, scrollController) => ListView(
                  controller: scrollController,
                  children: [
                    Align(
                      key: redBoxKey,
                      alignment: Alignment.topRight,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: curW,
                        height: curH,
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text(
                          "Video $curIndexVideo",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: AnimatedOpacity(
                        opacity: opacity,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: curW,
                          height: 1000,
                          color: Colors.blueGrey,
                          alignment: Alignment.center,
                          child: Text(
                            "data $curIndexVideo",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
