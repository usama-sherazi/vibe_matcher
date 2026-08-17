import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/shared_widgets.dart';

class CropPhotoScreen extends StatefulWidget {
  const CropPhotoScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<CropPhotoScreen> createState() => _CropPhotoScreenState();
}

class _CropPhotoScreenState extends State<CropPhotoScreen> {
  final _controller = CropController();
  bool _cropping = false;

  void _startCrop() {
    if (_cropping) return;
    setState(() => _cropping = true);
    _controller.cropCircle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Adjust photo'),
        actions: [
          TextButton(
            onPressed: _cropping ? null : _startCrop,
            child: const Text(
              'Use photo',
              style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Crop(
              image: widget.imageBytes,
              controller: _controller,
              aspectRatio: 1,
              withCircleUi: true,
              baseColor: Colors.black,
              maskColor: Colors.black.withValues(alpha: 0.55),
              onCropped: (bytes) {
                if (mounted) Navigator.of(context).pop(bytes);
              },
              onStatusChanged: (status) {
                if (status == CropStatus.ready && _cropping && mounted) {
                  setState(() => _cropping = false);
                }
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                children: [
                  Text(
                    'Move and pinch until your face sits in the circle. We’ll compress it to fit the profile.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  if (_cropping)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: CircularProgressIndicator(color: AppColors.coral),
                    )
                  else
                    VcButton(
                      label: 'Save cropped photo',
                      onPressed: _startCrop,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
