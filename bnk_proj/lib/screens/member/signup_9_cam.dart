import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:test_main/models/cust_info.dart';
import 'package:test_main/screens/member/signup_10.dart';

import '../app_colors.dart';

class IdCameraPage extends StatefulWidget {
  const IdCameraPage({super.key, required this.custInfo,});

  final CustInfo custInfo;


  @override
  State<IdCameraPage> createState() => _IdCameraPageState();
}

class _IdCameraPageState extends State<IdCameraPage> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(
      _cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller!),

          // 🔲 사각형 가이드
          _IdGuideOverlay(),

          // 상단 안내 문구
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "사각형 안에 신분증을 맞춰주세요",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // 하단 촬영 버튼
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                ),
              ),
            ),
          ),

          // 닫기 버튼
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final image = await _controller!.takePicture();

    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer =
        TextRecognizer(script: TextRecognitionScript.korean);

    final recognizedText =
        await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    if (!mounted) return;

    if (isOcrFailed(recognizedText.text)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 타이틀
                  const Text(
                    "신분증 인식 실패",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 설명 문구
                  Text(
                        "빛 반사가 없는 곳에서 다시\n촬영해주세요.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 확인 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pointDustyNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "재촬영",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IdCardConfirmPage(
          ocrText: recognizedText.text, custInfo: widget.custInfo,
        ),
      ),
    );
  }

  bool isOcrFailed(String text) {
    // 너무 짧으면 실패
    if (text.trim().length < 20) return true;

    // 이름 / 주민번호 / 날짜 중 하나라도 없으면 실패
    if (extractName(text) == null) return true;
    if (extractRrn(text) == null) return true;
    if (extractIssueDate(text) == null) return true;

    return false;
  }


}

class _IdGuideOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.85;
    final height = width * 0.63; // 신분증 비율

    return Center(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.9),
            width: 3,
          ),
        ),
      ),
    );
  }
}
