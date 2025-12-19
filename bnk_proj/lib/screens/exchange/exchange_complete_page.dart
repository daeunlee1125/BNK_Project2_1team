import 'package:flutter/material.dart';

class ExchangeCompletePage extends StatelessWidget {
  final String currency;
  final double foreignAmount;
  final int krwAmount;
  final double appliedRate;

  const ExchangeCompletePage({
    super.key,
    required this.currency,
    required this.foreignAmount,
    required this.krwAmount,
    required this.appliedRate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle,
                size: 48, color: Colors.blue),
            const SizedBox(height: 20),

            Text(
              "${foreignAmount.toStringAsFixed(2)} $currency\n샀어요",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 32),

            _row("환전 금액", "$krwAmount원 → $foreignAmount $currency"),
            _row("적용 환율", "${appliedRate.toStringAsFixed(2)}원"),
            _row("환전 수수료", "무료"),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (r) => r.isFirst);
                },
                child: const Text("확인"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
