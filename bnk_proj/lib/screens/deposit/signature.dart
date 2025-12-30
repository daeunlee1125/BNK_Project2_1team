import 'dart:typed_data';
import 'package:flutter/material.dart' hide Intent;
import 'package:flutter/services.dart';
import 'package:test_main/models/deposit/application.dart';
import 'package:test_main/services/deposit_draft_service.dart';
import 'package:test_main/services/deposit_service.dart';
import 'package:test_main/screens/app_colors.dart';
import '../../voice/controller/voice_session_controller.dart';
import '../../voice/scope/voice_session_scope.dart';
import '../deposit/step_4.dart';
import 'package:test_main/voice/core/voice_intent.dart';

/* =========================================================
   전자서명 단계
========================================================= */
enum AuthStep {
  selectMethod,
  inputInfo,
  agreeTerms,
  waitingAuth,
  completed,
}

class DepositSignatureScreen extends StatefulWidget {
  static const routeName = "/deposit-signature";
  final DepositApplication application;

  const DepositSignatureScreen({
    super.key,
    required this.application,
  });

  @override
  State<DepositSignatureScreen> createState() =>
      _DepositSignatureScreenState();
}

class _DepositSignatureScreenState extends State<DepositSignatureScreen> {
  AuthStep _step = AuthStep.selectMethod;

  String? _selectedMethod;
  Uint8List? _certificateImage;
  bool _inputInfoValid = false;

  final DepositDraftService _draftService =  DepositDraftService();

  bool _agreeAll = false;

  bool _agreeProductDesc = false;
  bool _agreeProductTerms = false;
  bool _agreeDepositBase = false;
  bool _agreeSignature = false;
  bool _agreeAuth = false;
  bool _agreePrivacy = false;

  bool _submitting = false;

  final _nameController = TextEditingController();
  final _rrnController = TextEditingController();
  final _phoneController = TextEditingController();

  bool get _allAgreed =>
      _agreeProductDesc &&
          _agreeProductTerms &&
          _agreeDepositBase &&
          _agreeSignature &&
          _agreeAuth &&
          _agreePrivacy;

  void _syncAgreeAll() {
    _agreeAll = _allAgreed;
  }

  late VoiceSessionController _voiceController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voiceController = VoiceSessionScope.of(context);
  }

  void _onInputInfoChanged() {
    final filled = _nameController.text.trim().isNotEmpty &&
        _rrnController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty;

    if (filled != _inputInfoValid) {
      setState(() {
        _inputInfoValid = filled;
      });
    }
  }


  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onInputInfoChanged);
    _rrnController.addListener(_onInputInfoChanged);
    _phoneController.addListener(_onInputInfoChanged);
    _onInputInfoChanged();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rrnController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.pointDustyNavy,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "전자서명",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _StepIndicator(step: _step),
            const SizedBox(height: 24),
            Expanded(child: _buildStep()),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case AuthStep.selectMethod:
        return _stepSelectMethod();
      case AuthStep.inputInfo:
        return _stepInputInfo();
      case AuthStep.agreeTerms:
        return _stepAgreeTerms();
      case AuthStep.waitingAuth:
        return _stepWaitingAuth();
      case AuthStep.completed:
        return _stepCompleted();
    }
  }

  Widget _stepSelectMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle("본인확인 수단 선택"),
        _AuthMethodCard(
          title: "카카오 인증서",
          description: "카카오톡 인증서를 이용한 본인확인",
          selected: _selectedMethod == "kakao",
          onTap: () => _selectMethod("kakao"),
        ),
        _AuthMethodCard(
          title: "통신사 PASS",
          description: "이동통신 3사 PASS 인증",
          selected: _selectedMethod == "pass",
          onTap: () => _selectMethod("pass"),
        ),
        _AuthMethodCard(
          title: "KB 인증서",
          description: "KB국민은행 공동 인증",
          selected: _selectedMethod == "kb",
          onTap: () => _selectMethod("kb"),
        ),
        _AuthMethodCard(
          title: "네이버 인증",
          description: "네이버 인증서를 이용한 본인확인",
          selected: _selectedMethod == "naver",
          onTap: () => _selectMethod("naver"),
        ),
        _AuthMethodCard(
          title: "토스 인증",
          description: "토스 앱을 통한 본인확인",
          selected: _selectedMethod == "toss",
          onTap: () => _selectMethod("toss"),
        ),
      ],
    );
  }

  void _selectMethod(String method) {
    setState(() {
      _selectedMethod = method;
      _step = AuthStep.inputInfo;
    });
  }

  Widget _stepInputInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle("본인 확인"),
        _InputField(
          controller: _nameController,
          hint: "이름",
          keyboardType: TextInputType.text,
          onChanged: (_) => _onInputInfoChanged(),
        ),
        _InputField(
          controller: _rrnController,
          hint: "주민등록번호 앞 6자리",
          keyboardType: TextInputType.number,
          onChanged: (_) => _onInputInfoChanged(),
        ),
        _InputField(
          controller: _phoneController,
          hint: "휴대폰 번호",
          keyboardType: TextInputType.phone,
          onChanged: (_) => _onInputInfoChanged(),
        ),
        const Spacer(),
        _PrimaryButton(
          text: "다음",
          enabled: _inputInfoValid,
          onPressed: () => setState(() => _step = AuthStep.agreeTerms),
        ),
      ],
    );
  }

  /* =========================================================
     STEP 3. 약관 동의
  ========================================================= */
  Widget _stepAgreeTerms() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle("약관 동의"),

                _SignatureNoticeBox(),

                const SizedBox(height: 20),

                _AgreementGroup(
                  title: "상품 관련 약관",
                  children: [
                    _AgreementTile(
                      value: _agreeProductDesc,
                      text: "상품설명서 확인 및 동의 (필수)",
                      onChanged: (v) {
                        setState(() {
                          _agreeProductDesc = v;
                          _syncAgreeAll();
                        });
                      },
                    ),
                    _AgreementTile(
                      value: _agreeProductTerms,
                      text: "상품약관 동의 (필수)",
                      onChanged: (v) {
                        setState(() {
                          _agreeProductTerms = v;
                          _syncAgreeAll();
                        });
                      },
                    ),
                    _AgreementTile(
                      value: _agreeDepositBase,
                      text: "예금거래기본약관 동의 (필수)",
                      onChanged: (v) {
                        setState(() {
                          _agreeDepositBase = v;
                          _syncAgreeAll();
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _AgreementGroup(
                  title: "전자서명 및 개인정보",
                  children: [
                    _AgreementTile(
                      value: _agreeSignature,
                      text: "전자서명 이용약관 동의 (필수)",
                      onChanged: (v) {
                        setState(() {
                          _agreeSignature = v;
                          _syncAgreeAll();
                        });
                      },
                    ),
                    _AgreementTile(
                      value: _agreeAuth,
                      text: "본인확인 서비스 이용약관 동의 (필수)",
                      onChanged: (v) {
                        setState(() {
                          _agreeAuth = v;
                          _syncAgreeAll();
                        });
                      },
                    ),
                    _AgreementTile(
                      value: _agreePrivacy,
                      text: "개인정보 수집 및 이용 동의 (필수)",
                      onChanged: (v) {
                        setState(() {
                          _agreePrivacy = v;
                          _syncAgreeAll();
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _AgreementTile(
                    value: _agreeAll,
                    text: "전체 약관에 동의합니다 (필수)",
                    small: true,
                    onChanged: (v) {
                      setState(() {
                        _agreeAll = v;
                        _agreeProductDesc = v;
                        _agreeProductTerms = v;
                        _agreeDepositBase = v;
                        _agreeSignature = v;
                        _agreeAuth = v;
                        _agreePrivacy = v;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        _PrimaryButton(
          text: "인증 요청",
          enabled: _allAgreed,
          onPressed: () => setState(() => _step = AuthStep.waitingAuth),
        ),
      ],
    );
  }


  Widget _stepWaitingAuth() {
    _simulateAuth();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(
          Icons.phone_android,
          size: 64,
          color: AppColors.pointDustyNavy,
        ),
        SizedBox(height: 24),

        CircularProgressIndicator(
          color: AppColors.pointDustyNavy,
        ),

        SizedBox(height: 28),

        Text(
          "본인확인 진행 중입니다",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.pointDustyNavy,
          ),
        ),

        SizedBox(height: 10),

        Text(
          "선택하신 인증 수단으로\n본인확인을 완료해 주세요.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: 6),

        Text(
          "인증이 완료되면 자동으로 다음 단계로 이동합니다.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _stepCompleted() {
    return Column(
      children: [
        const Icon(Icons.check_circle,
            size: 72, color: Colors.green),
        const SizedBox(height: 20),
        const Text(
          "전자서명이 완료되었습니다.",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        _PrimaryButton(
          text: "가입 완료",
          enabled: !_submitting,
          onPressed: _goToCompletion,
        ),
      ],
    );
  }

  Future<void> _simulateAuth() async {
    if (_certificateImage != null) return;

    await Future.delayed(const Duration(seconds: 2));
    final data = await rootBundle.load('images/chatboticon.png');

    setState(() {
      _certificateImage = data.buffer.asUint8List();
      widget.application.signatureImage = null;
      widget.application.signatureMethod = _selectedMethod;
      widget.application.signedAt = DateTime.now();
      _step = AuthStep.completed;
    });
  }

  Future<void> _goToCompletion() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {


      // 이어가기로 온 FX 상품인데 출금통화가 비어있으면 자동 세팅
      if (widget.application.withdrawType == "fx" &&
          (widget.application.fxWithdrawCurrency == null ||
              widget.application.fxWithdrawCurrency!.isEmpty)) {
        widget.application.fxWithdrawCurrency = widget.application.newCurrency;
      }

      // ======================
      //  Auto Renew / 만기 옵션 서버 맞춤 변환
      // ======================

      // autoRenew → Y / N 변환
      if (widget.application.autoRenew == "apply") {
        widget.application.autoRenew = "Y";
      } else {
        widget.application.autoRenew = "N";
      }


      // 🔥 KRW → 외화 예금 가입인데 withdrawType 이 fx 로 남아있으면 서버가 400 던짐
      if (widget.application.withdrawType == "fx" &&
          widget.application.newCurrency != "KRW") {
        widget.application.withdrawType = "krw";
        widget.application.selectedFxAccount = null;
        widget.application.fxWithdrawCurrency = null;
      }





      print("===== FINAL APPLICATION BEFORE SUBMIT =====");
      print(widget.application.toJson());


      // 이어가기 여부 / 어디서 온 신청인지 확인
      //print("isResumeDraft = ${widget.application.applicationSource}");

      final result =
      await DepositService().submitApplication(widget.application);



      // 전자서명과 계좌 생성이 끝났으면 이어가기 임시 테이블(TB_DPST_ACCT_DRAFT)도 정리한다.
      // 서버/DB 삭제 요청은 실패해도 가입 완료 이동은 막지 않도록 best-effort 로 수행한다.
      await _draftService.clearDraft(widget.application.dpstId);
      _voiceController.sendClientIntent(
        intent: Intent.success,
        productCode: widget.application.dpstId,
      );
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        DepositStep4Screen.routeName,
        arguments: DepositCompletionArgs(
          application: widget.application,
          result: result,
        ),
      );
    } catch (e, stack) {
      debugPrint("SUBMIT FAILED >>> $e");
      debugPrintStack(stackTrace: stack);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('가입 완료 처리 중 오류 발생: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }

  }
}

/* =========================================================
   STEP 3 전용 컴포넌트
========================================================= */

class _AgreementGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _AgreementGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mainPaleBlue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.pointDustyNavy,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _AgreementTile extends StatelessWidget {
  final bool value;
  final String text;
  final bool small;
  final ValueChanged<bool> onChanged;

  const _AgreementTile({
    required this.value,
    required this.text,
    required this.onChanged,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(
        text,
        style: TextStyle(fontSize: small ? 12.5 : 14.5),
      ),
    );
  }
}

class _SignatureNoticeBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.mainPaleBlue),
      ),
      child: const Text(
        "[전자서명 안내]\n"
            "본 동의는 전자서명 방식으로 처리되며 전자서명법 및 "
            "전자금융거래법에 따라 서면 서명과 동일한 법적 효력을 가집니다.\n\n"
            "[전자서명 동의서]\n"
            "상품설명서, 상품약관, 예금거래기본약관의 내용을 확인하였으며 "
            "전자서명에 동의합니다.",
        style: TextStyle(fontSize: 13, height: 1.5),
      ),
    );
  }
}

/* =========================================================
   공통 UI 컴포넌트
========================================================= */

class _StepIndicator extends StatelessWidget {
  final AuthStep step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        "STEP ${step.index + 1} / 5",
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.pointDustyNavy,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.pointDustyNavy,
        ),
      ),
    );
  }
}

class _AuthMethodCard extends StatelessWidget {
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _AuthMethodCard({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.pointDustyNavy
              : AppColors.mainPaleBlue,
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.pointDustyNavy,
          ),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: AppColors.mainPaleBlue),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: AppColors.mainPaleBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: AppColors.pointDustyNavy),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.text,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pointDustyNavy,
          disabledBackgroundColor: AppColors.mainPaleBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
