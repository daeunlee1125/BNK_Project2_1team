import 'package:flutter/material.dart';

import '../app_colors.dart';

class CameraExchangeScreen extends StatelessWidget {
  const CameraExchangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.6,
        title: const Text('AI 카메라 환율 변환'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '카메라로 영수증·가격표·현금을 비추면\n실시간으로 환율을 계산해드려요.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _cameraPreview(),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pointDustyNavy,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('사진 찍기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.pointDustyNavy,
                      side: const BorderSide(color: AppColors.pointDustyNavy),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('갤러리 선택'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _aiResultCard(),
            const SizedBox(height: 14),
            _rateSummary(),
            const SizedBox(height: 20),
            _safetyNotice(),
          ],
        ),
      ),
    );
  }

  Widget _cameraPreview() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mainPaleBlue, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'images/camera_placeholder.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.receipt_long, size: 46, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          '영수증이나 가격표를 촬영해주세요',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'AI 스캔 준비완료',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _aiResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: AppColors.pointDustyNavy),
              SizedBox(width: 8),
              Text(
                '인식된 금액',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.subIvoryBeige,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('USD 58.40',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text('→ 78,320원',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('적용 환율 (우대 60%)',
                  style: TextStyle(color: Colors.black54)),
              Text('1 USD = 1,341.2 KRW',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('수수료 예상', style: TextStyle(color: Colors.black54)),
              Text('포함 완료',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rateSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.mainPaleBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '한눈에 보는 환율 요약',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _chip('USD', selected: true),
              const SizedBox(width: 8),
              _chip('JPY'),
              const SizedBox(width: 8),
              _chip('EUR'),
              const Spacer(),
              Text(
                '10:24 기준',
                style: TextStyle(color: Colors.black.withOpacity(0.55)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.trending_up, color: Colors.redAccent),
              SizedBox(width: 6),
              Text('오늘 +0.42% 상승',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '카메라로 찍은 금액에 최신 환율과 우대가 자동 반영돼요.',
            style: TextStyle(color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.pointDustyNavy : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mainPaleBlue),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.pointDustyNavy,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _safetyNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            '촬영 팁',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text('• 영수증 전체가 화면에 들어오도록 해주세요.'),
          Text('• 어두운 장소에서는 플래시를 켜면 인식률이 올라갑니다.'),
          Text('• 현금 촬영 시 앞면 중앙이 잘 보이도록 비춰주세요.'),
        ],
      ),
    );
  }
}
