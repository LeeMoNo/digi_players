import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// 把裁剪结果收成正方形 JPEG，最长边 512。
Uint8List? encodeAvatar(Uint8List raw) {
  final decoded = img.decodeImage(raw);
  if (decoded == null) return null;
  final square = decoded.width == decoded.height
      ? decoded
      : img.copyResizeCropSquare(
          decoded,
          size: decoded.width < decoded.height ? decoded.width : decoded.height,
        );
  final side = square.width < 512 ? square.width : 512;
  final resized = square.width == side
      ? square
      : img.copyResize(
          square,
          width: side,
          height: side,
          interpolation: img.Interpolation.linear,
        );
  return img.encodeJpg(resized, quality: 85);
}

/// 选图之后的确认页。取消返回空，确认返回要上传的字节。
class AvatarCropScreen extends StatefulWidget {
  const AvatarCropScreen({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  State<AvatarCropScreen> createState() => _AvatarCropScreenState();
}

class _AvatarCropScreenState extends State<AvatarCropScreen> {
  final _controller = CropController();
  var _cropping = false;

  void _confirm() {
    if (_cropping) return;
    setState(() => _cropping = true);
    _controller.crop();
  }

  void _onCropped(CropResult result) {
    if (!mounted) return;
    if (result is! CropSuccess) {
      setState(() => _cropping = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('这张图裁不了，请换一张')));
      return;
    }
    final encoded = encodeAvatar(result.croppedImage);
    if (encoded == null) {
      setState(() => _cropping = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('这张图裁不了，请换一张')));
      return;
    }
    Navigator.of(context).pop(encoded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: _cropping ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        title: const Text('裁剪头像'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: Colors.black,
              child: Crop(
                image: widget.bytes,
                controller: _controller,
                onCropped: _onCropped,
                withCircleUi: true,
                aspectRatio: 1,
                interactive: true,
                fixCropRect: true,
                baseColor: Colors.black,
                maskColor: const Color(0x99000000),
                initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
                  size: 0.9,
                  aspectRatio: 1,
                ),
                cornerDotBuilder: (_, __) => const SizedBox.shrink(),
                progressIndicator: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _cropping ? null : _confirm,
                  child: _cropping
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('使用这张头像'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
