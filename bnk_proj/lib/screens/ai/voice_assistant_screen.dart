import 'package:flutter/material.dart';

import '../app_colors.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  bool _isListening = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.6,
        title: const Text('AI 음성비서'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_voice_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          _headerCard(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const SizedBox(height: 12),
                _conversationBubble(
                  speaker: 'AI 비서',
                  content: '안녕하세요, 무엇을 도와드릴까요?\n환율 조회나 송금 안내도 가능합니다.',
                  isUser: false,
                ),
                _conversationBubble(
                  speaker: '나',
                  content: '이번 주 유럽 여행에 필요한 유로 환전 알려줘.',
                  isUser: true,
                ),
                _conversationBubble(
                  speaker: 'AI 비서',
                  content: '현재 1 EUR = 1,450원이에요.\n우대 환율 적용하면 약 1,410원으로 안내드릴게요.',
                  isUser: false,
                ),
                const SizedBox(height: 14),
                _suggestionTitle('바로 말할 수 있어요'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('오늘 환율 알려줘'),
                    _chip('내 카드 결제 일정 보여줘'),
                    _chip('부산 여행지 추천해줘'),
                    _chip('송금 수수료 계산해줘'),
                  ],
                ),
                const SizedBox(height: 14),
                _suggestionTitle('최근 요청'),
                _quickListItem('전세대출 금리 비교해줘'),
                _quickListItem('다음 주 서울-부산 KTX 시간표 알려줘'),
                _quickListItem('적금 만기일 알려줘'),
              ],
            ),
          ),
          _micController(),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.pointDustyNavy,
            AppColors.pointDustyNavy.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'BNK AI 음성비서가 당신의 일정을 챙겨드려요.\n음성으로 환율·송금·조회 기능을 빠르게 사용하세요.',
              style: TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conversationBubble({
    required String speaker,
    required String content,
    required bool isUser,
  }) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? AppColors.pointDustyNavy : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              speaker,
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              content,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mainPaleBlue),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _quickListItem(String text) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: const Icon(Icons.history, color: Colors.black45),
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.north_east, size: 18, color: Colors.black45),
      onTap: () {},
    );
  }

  Widget _micController() {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _isListening ? '듣고 있어요...' : '음성으로 질문하거나 명령해보세요',
              style: TextStyle(
                color: _isListening ? AppColors.pointDustyNavy : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isListening = !_isListening;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: _isListening ? 88 : 76,
                height: _isListening ? 88 : 76,
                decoration: BoxDecoration(
                  color: _isListening
                      ? AppColors.pointDustyNavy
                      : AppColors.mainPaleBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('길게 눌러 계속 말하기'),
          ],
        ),
      ),
    );
  }
}
