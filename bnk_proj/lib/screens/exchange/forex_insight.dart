import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color mainPaleBlue = Color(0xFFB7C9E2);
  static const Color subIvoryBeige = Color(0xFFF7F3EE);
  static const Color pointDustyNavy = Color(0xFF3C4F76);
  static const Color backgroundOffWhite = Color(0xFFFAFAFA);
}

class ForexInsightScreen extends StatefulWidget {
  const ForexInsightScreen({super.key});

  @override
  State<ForexInsightScreen> createState() => _ForexInsightScreenState();
}

class _ForexInsightScreenState extends State<ForexInsightScreen> {
  final List<_CurrencyRate> _rates = const [
    _CurrencyRate(
      code: 'USD/KRW',
      name: '미국 달러',
      rate: 1392.42,
      change: -4.12,
      dailyHigh: 1403.10,
      dailyLow: 1389.00,
    ),
    _CurrencyRate(
      code: 'JPY/KRW',
      name: '일본 엔화',
      rate: 9.15,
      change: 0.02,
      dailyHigh: 9.20,
      dailyLow: 9.10,
    ),
    _CurrencyRate(
      code: 'EUR/KRW',
      name: '유로',
      rate: 1510.08,
      change: 3.44,
      dailyHigh: 1518.20,
      dailyLow: 1507.55,
    ),
  ];

  final List<_RiskIndicator> _riskIndicators = const [
    _RiskIndicator(
      title: '환율 변동성',
      value: '0.83%',
      subtitle: '최근 30일 표준편차',
    ),
    _RiskIndicator(
      title: '시장 심리',
      value: '중립 ↔',
      subtitle: '위험 선호/회피 신호',
    ),
    _RiskIndicator(
      title: '환리스크 한도',
      value: '70% 사용',
      subtitle: '사전 설정 대비 노출도',
    ),
  ];

  final Map<String, bool> _alertEnabled = {
    'USD/KRW': true,
    'JPY/KRW': false,
    'EUR/KRW': true,
  };

  final Map<String, double> _alertTargets = {
    'USD/KRW': 1400,
    'JPY/KRW': 9.25,
    'EUR/KRW': 1520,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOffWhite,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '환율 · 환전 인사이트',
          style: TextStyle(
            color: AppColors.pointDustyNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.pointDustyNavy,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHighlightCard(),
          const SizedBox(height: 16),
          _buildSectionTitle('환율 조회'),
          const SizedBox(height: 8),
          ..._rates.map(_buildRateCard),
          const SizedBox(height: 16),
          _buildSectionTitle('환율 알림 설정'),
          const SizedBox(height: 8),
          ..._rates.map(_buildAlertCard),
          const SizedBox(height: 16),
          _buildSectionTitle('환율 리스크 지표'),
          const SizedBox(height: 8),
          _buildRiskGrid(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHighlightCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mainPaleBlue.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.swap_horizontal_circle_outlined,
              color: AppColors.pointDustyNavy,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '환율 조회, 알림, 리스크를 한눈에',
                  style: TextStyle(
                    color: AppColors.pointDustyNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '주요 통화 환율을 확인하고 지정가 알림을 설정하세요. 변동성 지표로 환리스크 노출도도 관리할 수 있습니다.',
                  style: TextStyle(
                    color: AppColors.pointDustyNavy,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.pointDustyNavy,
      ),
    );
  }

  Widget _buildRateCard(_CurrencyRate rate) {
    final Color changeColor =
    rate.change >= 0 ? Colors.redAccent : Colors.blueAccent;
    final String changeLabel = rate.change >= 0
        ? '+${rate.change.toStringAsFixed(2)}'
        : rate.change.toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.subIvoryBeige,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up,
              color: AppColors.pointDustyNavy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rate.code} · ${rate.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.pointDustyNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${rate.rate.toStringAsFixed(2)} KRW',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pointDustyNavy,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        changeLabel,
                        style: TextStyle(
                          color: changeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '고 ${rate.dailyHigh.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '저 ${rate.dailyLow.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right,
              color: AppColors.pointDustyNavy,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(_CurrencyRate rate) {
    final bool enabled = _alertEnabled[rate.code] ?? false;
    final double target = _alertTargets[rate.code] ?? rate.rate;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? AppColors.pointDustyNavy : AppColors.subIvoryBeige,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${rate.code} 지정가 알림',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.pointDustyNavy,
                ),
              ),
              Switch(
                value: enabled,
                activeColor: AppColors.pointDustyNavy,
                onChanged: (value) {
                  setState(() {
                    _alertEnabled[rate.code] = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '목표 환율 ${target.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    Slider(
                      value: target,
                      min: rate.rate * 0.95,
                      max: rate.rate * 1.05,
                      activeColor: AppColors.pointDustyNavy,
                      inactiveColor: AppColors.mainPaleBlue,
                      onChanged: enabled
                          ? (value) {
                        setState(() {
                          _alertTargets[rate.code] =
                              double.parse(value.toStringAsFixed(2));
                        });
                      }
                          : null,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mainPaleBlue.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '현재 ${rate.rate.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.pointDustyNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: _riskIndicators.length,
      itemBuilder: (context, index) {
        final indicator = _riskIndicators[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                indicator.title,
                style: const TextStyle(
                  color: AppColors.pointDustyNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                indicator.value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.pointDustyNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                indicator.subtitle,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pointDustyNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {},
            icon: const Icon(Icons.refresh),
            label: const Text('실시간 환율 새로고침'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.pointDustyNavy,
              side: const BorderSide(color: AppColors.pointDustyNavy),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {},
            icon: const Icon(Icons.swap_horiz),
            label: const Text('환전 지갑으로 이동'),
          ),
        ),
      ],
    );
  }
}

class _CurrencyRate {
  final String code;
  final String name;
  final double rate;
  final double change;
  final double dailyHigh;
  final double dailyLow;

  const _CurrencyRate({
    required this.code,
    required this.name,
    required this.rate,
    required this.change,
    required this.dailyHigh,
    required this.dailyLow,
  });
}

class _RiskIndicator {
  final String title;
  final String value;
  final String subtitle;

  const _RiskIndicator({
    required this.title,
    required this.value,
    required this.subtitle,
  });
}
