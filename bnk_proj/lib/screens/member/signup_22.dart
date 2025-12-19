import 'package:flutter/material.dart';
import 'package:test_main/screens/app_colors.dart';

import '../../models/cust_acct.dart';
import '../../models/cust_info.dart';

class AccountCreateCompletePage extends StatelessWidget {

  final CustInfo custInfo;
  final CustAcct custAcct;



  const AccountCreateCompletePage({super.key, required this.custInfo, required this.custAcct,});

  @override
  Widget build(BuildContext context) {

    debugPrint('📌 AccountCreateCompletePage 진입');
    debugPrint('custInfo = ${custInfo.toJson()}');
    debugPrint('custAcct = ${custAcct.toJson()}');

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),

              // 캐릭터 이미지
              Image.asset(
                'images/character10.png',
                width: 180,
                fit: BoxFit.contain,
              ),


              //  메인 문구
              const Text(
                '입출금 통장이\n개설되었습니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 16),

              // 서브 문구
              const Text(
                '플로뱅크의 다양한 금융 서비스를\n이용해 보세요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const Spacer(),

              // ▶ 확인 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                  
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pointDustyNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
