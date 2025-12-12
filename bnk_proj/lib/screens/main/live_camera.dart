import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;

class LiveCameraPage extends StatefulWidget {
  const LiveCameraPage({super.key});

  @override
  State<LiveCameraPage> createState() => _LiveCameraPageState();
}

class _LiveCameraPageState extends State<LiveCameraPage> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isBusy = false;

  String _detectedText = "가격을 비춰주세요";
  String _convertedPrice = "";
  double _detectedAmount = 0.0;

  // UI 상태 관리 변수
  bool _showCurrencySelector = false;
  String _selectedCurrency = 'USD';

  final Map<String, double> _exchangeRates = {
    'USD': 1320.50,
    'JPY': 9.12,
    'EUR': 1430.20,
    'CNY': 185.50,
  };

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await Permission.camera.request();
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final firstCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    _controller!.startImageStream(_processCameraImage);

    if (mounted) setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isBusy = false;
        return;
      }

      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      _analyzeText(recognizedText.text);

    } catch (e) {
      print("Error analyzing image: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      _isBusy = false;
    }
  }

  void _analyzeText(String text) {
    RegExp dollarRegex = RegExp(r'\$\s?([0-9,.]+)');
    RegExp numberRegex = RegExp(r'([0-9,]+(\.[0-9]{1,2})?)');

    Match? dollarMatch = dollarRegex.firstMatch(text);
    Match? numberMatch = numberRegex.firstMatch(text);

    if (dollarMatch != null && mounted) {
      String priceStr = dollarMatch.group(1)!.replaceAll(',', '');
      if (priceStr.endsWith('.')) priceStr = priceStr.substring(0, priceStr.length - 1);

      double price = double.tryParse(priceStr) ?? 0.0;

      if (price > 0 && price < 10000000) {
        setState(() {
          _detectedAmount = price;
          _selectedCurrency = 'USD';
          _showCurrencySelector = false;
          _calculateResult();
        });
      }
    }
    else if (numberMatch != null && mounted) {
      String priceStr = numberMatch.group(1)!.replaceAll(',', '');
      if (priceStr.endsWith('.')) priceStr = priceStr.substring(0, priceStr.length - 1);

      double price = double.tryParse(priceStr) ?? 0.0;

      if (price > 0 && price < 10000000) {
        if (_detectedAmount != price || !_showCurrencySelector) {
          setState(() {
            _detectedAmount = price;
            _showCurrencySelector = true;
            _detectedText = "${_detectedAmount.toStringAsFixed(2)}";
            _convertedPrice = "통화 종류를 선택해주세요";
          });
        }
      }
    }
  }

  //  [중요] 함수 이름이 _calculateResult 입니다.
  void _calculateResult() {
    double rate = _exchangeRates[_selectedCurrency]!;
    int krw = (_detectedAmount * rate).toInt();

    DateTime now = DateTime.now();
    String today = "${now.year}.${now.month}.${now.day}";

    String symbol = _selectedCurrency == 'USD' ? '\$' : '';

    setState(() {
      if (_selectedCurrency == 'USD') {
        _detectedText = "$symbol${_detectedAmount.toStringAsFixed(2)}";
      } else {
        _detectedText = "${_detectedAmount.toStringAsFixed(2)} ($_selectedCurrency)";
      }

      _convertedPrice = "약 ${_formatCurrency(krw)}원\n($today 기준)";
    });
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
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
      body: Stack(
        children: [
          SizedBox.expand(
            child: CameraPreview(_controller!),
          ),

          Positioned(
            top: 0, left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: Container(
              width: 250, height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              // ▼ 여기가 블러 처리의 핵심입니다.
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // 블러 강도 증가 (10 -> 15)
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  decoration: BoxDecoration(
                    // ▼ 투명도를 0.9 -> 0.65로 낮춰서 뒤가 비치게 함
                    color: Colors.white.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5), // 테두리 강조
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 상단 핸들
                      Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.black12, // 핸들 색상을 배경에 맞춰 조정
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // (1) 인식된 텍스트
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.center_focus_weak, size: 16, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(
                            _detectedText,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54, // 흰 배경이 연해졌으므로 글자는 진하게
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // (2) 통화 선택 버튼 (Chips)
                      if (_showCurrencySelector) ...[
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _exchangeRates.keys.map((currency) {
                              bool isSelected = _selectedCurrency == currency;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: ChoiceChip(
                                  label: Text(currency),
                                  selected: isSelected,
                                  showCheckmark: false,
                                  selectedColor: const Color(0xFF3E5D9C),
                                  // 칩 배경도 약간 투명하게
                                  backgroundColor: Colors.white.withOpacity(0.7),
                                  side: BorderSide.none,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  onSelected: (bool selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedCurrency = currency;
                                        _calculateResult();
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // (3) 변환된 가격
                      if (_convertedPrice.isEmpty)
                        const Text(
                          "가격을 비춰보세요",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E5D9C),
                          ),
                        )
                      else ...[
                        Text(
                          _convertedPrice.split('\n')[0], // 가격
                          style: const TextStyle(
                            fontSize: 34, // 크기 키움
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3E5D9C),
                            letterSpacing: -0.5,
                            height: 1.0,
                          ),
                        ),
                        if (_convertedPrice.contains('\n')) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5), // 날짜 박스 투명하게
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _convertedPrice.split('\n')[1], // 날짜
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;
    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;
    final orientations = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    final rotationCompensation = (orientations[DeviceOrientation.portraitUp]! + sensorOrientation + 360) % 360;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(rotationCompensation) ?? InputImageRotation.rotation0deg,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }
}