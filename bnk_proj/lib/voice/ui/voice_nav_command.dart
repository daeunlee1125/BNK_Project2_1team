enum VoiceNavType {
  openDepositList,
  openDepositView,
  selectDepositTab, // 상품/금리/약관
  openJoinFlow,
  openInput,
  openSignature,
}

class VoiceNavCommand {
  final VoiceNavType type;
  final String? productCode;
  final int? tabIndex;

  VoiceNavCommand({
    required this.type,
    this.productCode,
    this.tabIndex,
  });
}
