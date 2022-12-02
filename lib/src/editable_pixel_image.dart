import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pixels/pixels.dart';

/// A [PixelImage] that can be manipulated using the [PixelImageController].
class EditablePixelImage extends StatefulWidget {
  /// The controller controlling this image.
  final PixelImageController controller;

  /// Callback for when a pixel is tapped on the image.
  final void Function(PixelTapDetails details)? onTappedPixel;

  /// Creates a new [EditablePixelImage].
  const EditablePixelImage({
    required this.controller,
    required this.onTappedPixel,
    super.key,
  });

  @override
  State<EditablePixelImage> createState() => _EditablePixelImageState();
}

class _EditablePixelImageState extends State<EditablePixelImage> {
  Point<int>? lastTapPos;
  Point<int> mousePos = const Point(0, 0);

  GlobalKey pixelImageKey = GlobalKey(debugLabel: "pixelImageWidget");

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_pixelValueChanged);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_pixelValueChanged);
  }

  void _pixelValueChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final double aspectRatio =
        widget.controller.width / widget.controller.height;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: LayoutBuilder(builder: (context, constraints) {
        final tapHandler = makeTapHandler(constraints);

        return GestureDetector(
          onTapDown: tapHandler,
          onPanUpdate: tapHandler,
          onTapUp: dragEndHandler,
          onPanEnd: dragEndHandler,
          child: Stack(children: [
            PixelImage(
              key: pixelImageKey,
              width: widget.controller.value.width,
              height: widget.controller.value.height,
              palette: widget.controller.value.palette,
              pixels: widget.controller.value.pixels,
            ),
            CustomPaint(
              painter: CursorToolPainter(mousePos, widget.controller.brushSize,
                  widget.controller.brushColor, pixelImageKey),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.none,
              onHover: (event) => {
                setState(() {
                  mousePos = Point(event.localPosition.dx.toInt(),
                      event.localPosition.dy.toInt());
                })
              },
            )
          ]),
        );
      }),
    );
  }

  void dragEndHandler(_) {
    /* erases on drag end */
    lastTapPos = null;
  }

  void Function(dynamic) makeTapHandler(constraints) {
    return (details) {
      // Do nothing if there is no callback supplied
      if (widget.onTappedPixel == null) return;

      var xLocal = details.localPosition.dx;
      var yLocal = details.localPosition.dy;

      int x = widget.controller.width * xLocal ~/ constraints.maxWidth;
      int y = widget.controller.height * yLocal ~/ constraints.maxHeight;

      Point<int> newTapPos = Point(x, y);

      // Update the mouse pos in local coordinates so it moves with us
      mousePos = Point(xLocal.toInt(), yLocal.toInt());

      // interpolate through missed pixels when dragging and plot them as well
      if (lastTapPos != null) {
        Point<int> delta = newTapPos - lastTapPos!;
        while (delta.x != 0 || delta.y != 0) {
          if (delta.x < 0) {
            delta = Point(delta.x + 1, delta.y);
          } else if (delta.x > 0) {
            delta = Point(delta.x - 1, delta.y);
          }

          if (delta.y < 0) {
            delta = Point(delta.x, delta.y + 1);
          } else if (delta.y > 0) {
            delta = Point(delta.x, delta.y - 1);
          }

          // plot the delta pixels
          plotPixelWithBrush(lastTapPos!.x + delta.x, lastTapPos!.y + delta.y,
              details.localPosition);
        }
      } else {
        // directly plot the one pixel
        plotPixelWithBrush(x, y, details.localPosition);
      }

      lastTapPos = newTapPos;
    };
  }

  void plotPixelWithBrush(int x, int y, Offset localPosition) {
    int r = widget.controller.brushSize ~/ 2;
    for (int i = 0; i <= r; i++) {
      for (int j = 0; j <= r; j++) {
        if (i * i + j * j > r * r) {
          continue;
        }

        int x1 = x + i;
        int x2 = x - i;
        int y1 = y + j;
        int y2 = y - j;
        widget.onTappedPixel!(
          PixelTapDetails._(
            x: x1,
            y: y1,
            index: y1 * widget.controller.width + x1,
            localPosition: localPosition,
          ),
        );
        widget.onTappedPixel!(
          PixelTapDetails._(
            x: x2,
            y: y1,
            index: y1 * widget.controller.width + x2,
            localPosition: localPosition,
          ),
        );
        widget.onTappedPixel!(
          PixelTapDetails._(
            x: x1,
            y: y2,
            index: y2 * widget.controller.width + x1,
            localPosition: localPosition,
          ),
        );
        widget.onTappedPixel!(
          PixelTapDetails._(
            x: x2,
            y: y2,
            index: y2 * widget.controller.width + x2,
            localPosition: localPosition,
          ),
        );
      }
    }
  }
}

/// Draws the custom tool type indicator at the mouse position
class CursorToolPainter extends CustomPainter {
  /// The position of the mouse
  Point<int> pos;

  /// The diameter of the brush in pixels used when painting
  int brushSize;

  /// The color of the brush
  Color brushColor;

  /// The context key for the canvas widget we draw to
  GlobalKey pixelCanvasWidget;

  /// Draws the tool type indicator at the [pos] with
  /// size [brushSize] with respect to [pixelCanvasWidget]
  /// with custom color [brushColor]
  CursorToolPainter(
      this.pos, this.brushSize, this.brushColor, this.pixelCanvasWidget);

  @override
  void paint(Canvas canvas, Size size) {
    Size? pixelCanvasSize = pixelCanvasWidget.currentContext?.size;

    if (pixelCanvasSize == null) return;

    PixelImage image = pixelCanvasWidget.currentWidget as PixelImage;
    final double canvasScale = (pixelCanvasSize.height / image.height) * 0.5;

    Paint paint = Paint();
    paint.color = brushColor;
    paint.isAntiAlias = false;
    paint.strokeWidth = brushSize.toDouble();
    canvas.drawCircle(Offset(pos.x.toDouble(), pos.y.toDouble()),
        brushSize.toDouble() * canvasScale, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// Provides details about a tapped pixel on an [EditablePixelImage].
class PixelTapDetails {
  /// The x location of the pixel.
  final int x;

  /// The y location of the pixel.
  final int y;

  /// The index of the pixel in the [ByteData] of the image.
  final int index;

  /// Position in coordinates local to the Widget itself.
  final Offset localPosition;

  const PixelTapDetails._({
    required this.x,
    required this.y,
    required this.index,
    required this.localPosition,
  });
}

class _PixelImageValue {
  final ByteData pixels;
  final PixelPalette? palette;
  final int width;
  final int height;

  const _PixelImageValue({
    required this.pixels,
    this.palette,
    required this.width,
    required this.height,
  });
}

/// Controller for an [EditablePixelImage]. Use it to listen to taps on the
/// image or to set or replace pixels in the image.
class PixelImageController extends ValueNotifier<_PixelImageValue> {
  late Uint8List _pixelBytes;

  /// The palette of the [EditablePixelImage] controlled by the controller.
  final PixelPalette? palette;

  /// The custom color gradient
  final Color Function(double y)? customGradientEquation;

  /// Height in pixels of the [EditablePixelImage] controlled by the controller.
  final int height;

  /// Width in pixels of the [EditablePixelImage] controlled by the controller.
  final int width;

  /// Brush color
  Color brushColor;

  /// Brush size
  int brushSize;

  /// Callback when a pixel is tapped on the [EditablePixelImage] controlled by
  /// the controller.
  final void Function(PixelTapDetails details)? onTappedPixel;

  /// Creates a new [PixelImageController].
  PixelImageController({
    ByteData? pixels,
    this.palette,
    this.customGradientEquation,
    Color? bgColor,
    required this.width,
    required this.height,
    this.onTappedPixel,
    this.brushSize = 1,
    this.brushColor = Colors.white,
  }) : super(_PixelImageValue(
          pixels: pixels ?? _emptyPixels(width, height, bgColor),
          palette: palette,
          width: width,
          height: height,
        )) {
    _pixelBytes = value.pixels.buffer.asUint8List();
    assert(_pixelBytes.length == area * 4);
  }

  static ByteData _emptyPixels(int width, int height, Color? fill) {
    final area = width * height;
    var bytes = Uint8List(area * 4);

    if (fill != null) {
      for (int i = 0; i < area; i++) {
        bytes[i * 4 + 0] = fill.red;
        bytes[i * 4 + 1] = fill.green;
        bytes[i * 4 + 2] = fill.blue;
        bytes[i * 4 + 3] = fill.alpha;
      }
    }
    return bytes.buffer.asByteData();
  }

  /// Gets or sets the [ByteData] of the [EditablePixelImage] controlled by the
  /// controller.
  ByteData get pixels => _pixelBytes.buffer.asByteData();

  /// calculate the image's 2D area
  int get area => width * height;

  set pixels(ByteData pixels) {
    assert(pixels.lengthInBytes == area * 4);
    _pixelBytes = pixels.buffer.asUint8List();
    _update();
  }

  /// Sets a specific pixel in the [EditablePixelImage] controlled by the
  /// controller.
  void setPixel({
    required Color color,
    required int x,
    required int y,
  }) {
    setPixelIndex(
      pixelIndex: y * width + x,
      color: color,
    );
    _update();
  }

  /// Sets a specific pixel in the [EditablePixelImage] controlled by the
  /// controller.
  void setPixelIndex({
    required pixelIndex,
    required color,
  }) {
    if (pixelIndex < 0 || (pixelIndex * 4 + 3) >= _pixelBytes.length) return;
    _pixelBytes[pixelIndex * 4 + 0] = color.red;
    _pixelBytes[pixelIndex * 4 + 1] = color.green;
    _pixelBytes[pixelIndex * 4 + 2] = color.blue;
    _pixelBytes[pixelIndex * 4 + 3] = color.alpha;
    _update();
  }

  /// Updates the brush [size] in pixels and [color]
  void setBrush(int size, Color color) {
    brushSize = size;
    brushColor = color;
    _update();
  }

  void _update() {
    value = _PixelImageValue(
      pixels: pixels,
      palette: palette,
      width: width,
      height: height,
    );
  }
}
