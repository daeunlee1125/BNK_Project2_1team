import 'dart:convert';
import 'dart:typed_data';
import 'view.dart';

/// 예금 가입 플로우에서 사용하는 신청 정보 모델
class DepositApplication {
  DepositApplication({required this.dpstId});

  final String dpstId;
  String? customerName;
  String? customerCode;

  // Step1 agreements
  bool agree1 = false;
  bool agree2 = false;
  bool agree3 = false;
  bool info1 = false;
  bool info2 = false;
  bool info3 = false;
  bool important1 = false;
  bool important2 = false;
  bool important3 = false;
  bool finalAgree = false;

  // Step2 input
  String withdrawType = 'krw';
  String? selectedKrwAccount;
  String? selectedFxAccount;
  String? fxWithdrawCurrency;
  String? withdrawPassword;

  String newCurrency = '';
  int? newAmount;
  int? newPeriodMonths;

  String autoRenew = 'no';
  int? autoRenewCycle;
  int? autoRenewCount;
  bool autoTerminateAtMaturity = false;

  double? appliedRate;
  double? appliedFxRate;

  bool addPaymentEnabled = false;
  int? addPaymentCount;

  bool partialWithdrawEnabled = false;
  int? partialWithdrawCount;

  String depositPassword = '';

  // DB 컬럼 매핑용 추가 필드
  String? dpstHdrStartDy;
  String? dpstHdrFinDy;
  String? dpstHdrCurrencyExp;
  String? dpstHdrLinkedAcctNo;
  int? dpstHdrLinkedAcctType;
  String dpstHdrAutoRenewYn = 'N';
  int dpstHdrAutoRenewCnt = 0;
  int? dpstHdrAutoRenewTerm;
  String? dpstHdrInfoAgreeYn;
  DateTime? dpstHdrInfoAgreeDt;
  DateTime? dpstHdrContractDt;
  String? dpstHdrExpAcctNo;
  int dpstHdrAddPayCnt = 0;
  int? dpstHdrPartWdrwCnt;
  double? dpstHdrLinkedAcctBal;

  int dpstDtlType = 1;
  String? dpstDtlEsignYn;
  DateTime? dpstDtlEsignDt;


  // Product meta for UI/flow
  DepositProduct? product;

  // Signature
  Uint8List? signatureImage;
  String? signatureMethod;
  DateTime? signedAt;

  Map<String, dynamic> toJson() {
    //  1️⃣ 출금 계좌 / 유형 매핑
    String? withdrawAccountNo;
    int? withdrawAccountType;

    if (withdrawType == 'krw') {
      // 원화 출금
      withdrawAccountNo = selectedKrwAccount;
      withdrawAccountType = 1; // 원화 계좌

      // 원화 출금이면 외화 출금 통화 의미 없음 → 정리
      fxWithdrawCurrency = null;
    } else if (withdrawType == 'fx') {
      // 외화 출금
      withdrawAccountNo = selectedFxAccount;
      withdrawAccountType = 2; // 외화 계좌

      // 외화 출금인데 통화가 비었으면 예금통화로 채워줌
      if (fxWithdrawCurrency == null || fxWithdrawCurrency!.isEmpty) {
        fxWithdrawCurrency = newCurrency;
      }
    }

    //  2️⃣ JSON 변환
    return {
      'dpstId': dpstId,
      'customerCode': customerCode,

      'agreements': {
        'agree1': agree1,
        'agree2': agree2,
        'agree3': agree3,
        'info1': info1,
        'info2': info2,
        'info3': info3,
        'important1': important1,
        'important2': important2,
        'important3': important3,
        'finalAgree': finalAgree,
      },

      // Step2 값은 그대로 유지
      'withdrawType': withdrawType,
      'selectedKrwAccount': selectedKrwAccount,
      'selectedFxAccount': selectedFxAccount,
      'fxWithdrawCurrency': fxWithdrawCurrency,
      'withdrawPassword': withdrawPassword,

      'newCurrency': newCurrency,
      'newAmount': newAmount,
      'newPeriodMonths': newPeriodMonths,

      'autoRenew': autoRenew,
      'autoRenewCycle': autoRenewCycle,
      'autoRenewCount': autoRenewCount,
      'autoTerminateYn': autoTerminateAtMaturity ? 'Y' : 'N',

      'appliedRate': appliedRate,
      'appliedFxRate': appliedFxRate,

      'addPaymentEnabled': addPaymentEnabled,
      'addPaymentCount': addPaymentCount,
      'partialWithdrawEnabled': partialWithdrawEnabled,
      'partialWithdrawCount': partialWithdrawCount,

      'depositPassword': depositPassword,

      'dpstHdrStartDy': dpstHdrStartDy,
      'dpstHdrFinDy': dpstHdrFinDy,
      'dpstHdrCurrencyExp': dpstHdrCurrencyExp,

      // 🔥 여기 두 줄이 진짜 핵심 (서버에서 사용하는 최종 출금 계좌값)
      'dpstHdrLinkedAcctNo': withdrawAccountNo ?? dpstHdrLinkedAcctNo,
      'dpstHdrLinkedAcctType': withdrawAccountType ?? dpstHdrLinkedAcctType,

      'dpstHdrAutoRenewYn': dpstHdrAutoRenewYn,
      'dpstHdrAutoRenewCnt': dpstHdrAutoRenewCnt,
      'dpstHdrAutoRenewTerm': dpstHdrAutoRenewTerm,

      'dpstHdrInfoAgreeYn': dpstHdrInfoAgreeYn,
      'dpstHdrInfoAgreeDt': dpstHdrInfoAgreeDt?.toIso8601String(),
      'dpstHdrContractDt': dpstHdrContractDt?.toIso8601String(),
      'dpstHdrExpAcctNo': dpstHdrExpAcctNo,
      'dpstHdrAddPayCnt': dpstHdrAddPayCnt,
      'dpstHdrPartWdrwCnt': dpstHdrPartWdrwCnt,
      'dpstHdrLinkedAcctBal': dpstHdrLinkedAcctBal,

      'dpstDtlType': dpstDtlType,
      'dpstDtlEsignYn': dpstDtlEsignYn,
      'dpstDtlEsignDt': dpstDtlEsignDt?.toIso8601String(),

      'signature': signatureImage != null ? base64Encode(signatureImage!) : null,
      'signatureMethod': signatureMethod,
      'signedAt': signedAt?.toIso8601String(),
    };
  }


  factory DepositApplication.fromJson(Map<String, dynamic> json) {
    final agreements = json['agreements'] as Map<String, dynamic>? ?? {};
    return DepositApplication(dpstId: json['dpstId']?.toString() ?? '')
      ..customerCode = json['customerCode']?.toString()
      ..customerName = json['customerName']?.toString()
      ..agree1 = agreements['agree1'] == true
      ..agree2 = agreements['agree2'] == true
      ..agree3 = agreements['agree3'] == true
      ..info1 = agreements['info1'] == true
      ..info2 = agreements['info2'] == true
      ..info3 = agreements['info3'] == true
      ..important1 = agreements['important1'] == true
      ..important2 = agreements['important2'] == true
      ..important3 = agreements['important3'] == true
      ..finalAgree = agreements['finalAgree'] == true
      ..withdrawType = json['withdrawType']?.toString() ?? 'krw'
      ..selectedKrwAccount = json['selectedKrwAccount']?.toString()
      ..selectedFxAccount = json['selectedFxAccount']?.toString()
      ..fxWithdrawCurrency = json['fxWithdrawCurrency']?.toString()
      ..withdrawPassword = json['withdrawPassword']?.toString()
      ..newCurrency = json['newCurrency']?.toString() ?? ''
      ..newAmount = json['newAmount'] as int?
      ..newPeriodMonths = json['newPeriodMonths'] as int?
      ..autoRenew = json['autoRenew']?.toString() ?? 'no'
      ..autoRenewCycle = json['autoRenewCycle'] as int?
      ..autoRenewCount = json['autoRenewCount'] as int?
      ..autoTerminateAtMaturity =
          json['autoTerminateAtMaturity'] == true ||
              json['autoTerminateYn']?.toString().toUpperCase() == 'Y'

      ..appliedRate = _tryParseDouble(json['appliedRate'])
      ..appliedFxRate = _tryParseDouble(json['appliedFxRate'])
      ..addPaymentEnabled = json['addPaymentEnabled'] == true ||
          json['addPaymentEnabled']?.toString().toUpperCase() == 'Y'
      ..addPaymentCount = json['addPaymentCount'] as int?
      ..partialWithdrawEnabled = json['partialWithdrawEnabled'] == true ||
          json['partialWithdrawEnabled']?.toString().toUpperCase() == 'Y'
      ..partialWithdrawCount = json['partialWithdrawCount'] as int?
      ..depositPassword = json['depositPassword']?.toString() ?? ''
      ..dpstHdrStartDy = json['dpstHdrStartDy']?.toString()
      ..dpstHdrFinDy = json['dpstHdrFinDy']?.toString()
      ..dpstHdrCurrencyExp = json['dpstHdrCurrencyExp']?.toString()
      ..dpstHdrLinkedAcctNo = json['dpstHdrLinkedAcctNo']?.toString()
      ..dpstHdrLinkedAcctType = json['dpstHdrLinkedAcctType'] as int?
      ..dpstHdrAutoRenewYn = json['dpstHdrAutoRenewYn']?.toString() ?? 'N'
      ..dpstHdrAutoRenewCnt = json['dpstHdrAutoRenewCnt'] as int? ?? 0
      ..dpstHdrAutoRenewTerm = json['dpstHdrAutoRenewTerm'] as int?
      ..dpstHdrInfoAgreeYn = json['dpstHdrInfoAgreeYn']?.toString()
      ..dpstHdrInfoAgreeDt = json['dpstHdrInfoAgreeDt'] != null
          ? DateTime.tryParse(json['dpstHdrInfoAgreeDt'].toString())
          : null
      ..dpstHdrContractDt = json['dpstHdrContractDt'] != null
          ? DateTime.tryParse(json['dpstHdrContractDt'].toString())
          : null
      ..dpstHdrExpAcctNo = json['dpstHdrExpAcctNo']?.toString()
      ..dpstHdrAddPayCnt = json['dpstHdrAddPayCnt'] as int? ?? 0
      ..dpstHdrPartWdrwCnt = json['dpstHdrPartWdrwCnt'] as int?
      ..dpstHdrLinkedAcctBal =
      (json['dpstHdrLinkedAcctBal'] as num?)?.toDouble()
      ..dpstDtlType = json['dpstDtlType'] as int? ?? 1
      ..dpstDtlEsignYn = json['dpstDtlEsignYn']?.toString()
      ..dpstDtlEsignDt = json['dpstDtlEsignDt'] != null
          ? DateTime.tryParse(json['dpstDtlEsignDt'].toString())
          : null
      ..signatureImage = _decodeSignature(json['signature'])
      ..signatureMethod = json['signatureMethod']?.toString()
      ..signedAt = json['signedAt'] != null
          ? DateTime.tryParse(json['signedAt'].toString())
          : null;
  }

  static Uint8List? _decodeSignature(dynamic value) {
    if (value == null) return null;
    try {
      return base64Decode(value.toString());
    } catch (_) {
      return null;
    }
  }

  static double? _tryParseDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }
}

class DepositSubmissionResult {
  final String customerName;
  final String productName;
  final String newAccountNo;
  final String currency;
  final String amount;
  final String? rate;
  final String? maturityDate;
  final String? periodLabel;
  final String? withdrawalAccount;
  final String? withdrawCurrency;
  final String? withdrawAmount;
  final String? autoRenewLabel;
  final String? contractDateTime;

  const DepositSubmissionResult({
    required this.customerName,
    required this.productName,
    required this.newAccountNo,
    required this.currency,
    required this.amount,
    this.rate,
    this.maturityDate,
    this.periodLabel,
    this.withdrawalAccount,
    this.withdrawCurrency,
    this.withdrawAmount,
    this.autoRenewLabel,
    this.contractDateTime,
  });

  factory DepositSubmissionResult.fromJson(Map<String, dynamic> json) {
    return DepositSubmissionResult(
      customerName: json['customerName']?.toString() ?? '고객',
      productName: json['productName']?.toString() ?? '외화정기예금',
      newAccountNo: json['newAccountNo']?.toString() ?? '',
      currency: json['currency']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '',
      rate: json['rate']?.toString(),
      maturityDate: json['maturityDate']?.toString(),
      periodLabel: json['periodLabel']?.toString(),
      withdrawalAccount: json['withdrawalAccount']?.toString(),
      withdrawCurrency: json['withdrawCurrency']?.toString(),
      withdrawAmount: json['withdrawAmount']?.toString(),
      autoRenewLabel: json['autoRenewLabel']?.toString(),
      contractDateTime: json['contractDateTime']?.toString(),
    );
  }
}

class DepositCompletionArgs {
  final DepositApplication application;
  final DepositSubmissionResult result;

  const DepositCompletionArgs({
    required this.application,
    required this.result,
  });
}