import 'package:flutter/material.dart';
import '../app_colors.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,

      // --------------------------
      // 상단 AppBar
      // --------------------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: true,
        centerTitle: true,

        title: const Text(
          "AI 상담 도우미",
          style: TextStyle(
            color: AppColors.pointDustyNavy,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),

        iconTheme: const IconThemeData(
          color: AppColors.pointDustyNavy,
        ),
      ),

      // --------------------------
      // 본문
      // --------------------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _chatConsole(),
          ],
        ),
      ),
    );
  }

  // ============================
  // 채팅 콘솔 UI (유일한 카드)
  // ============================

  Widget _chatConsole() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.12),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            "AI 상담 채팅",
            style: TextStyle(
              color: AppColors.pointDustyNavy,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),

          // --------------------------
          // 메시지들
          // --------------------------
          const _ChatBubble(
            isUser: false,
            name: "AI 도우미",
            time: "09:32",
            message: "안녕하세요! 무엇을 도와드릴까요?",
          ),
          const SizedBox(height: 14),

          const _ChatBubble(
            isUser: true,
            name: "나",
            time: "09:33",
            message: "해외 송금 우대 정보 알려줘!",
          ),
          const SizedBox(height: 14),

          const _ChatBubble(
            isUser: false,
            name: "AI 도우미",
            time: "09:33",
            message: "해외송금 우대는 최대 90%까지 제공됩니다!",
            suggestions: ["우대 신청", "자세히 보기"],
          ),

          const SizedBox(height: 20),

          // --------------------------
          // 입력창 UI
          // --------------------------
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "질문을 입력하세요...",
                    filled: true,
                    fillColor: AppColors.mainPaleBlue.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.pointDustyNavy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white),
              )
            ],
          )
        ],
      ),
    );
  }
}

// =========================================
// 채팅 버블 UI
// =========================================
class _ChatBubble extends StatelessWidget {
  final bool isUser;
  final String name;
  final String time;
  final String message;
  final List<String>? suggestions;

  const _ChatBubble({
    required this.isUser,
    required this.name,
    required this.time,
    required this.message,
    this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
      isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // 🔹 상담원 아바타 (이미지)
        if (!isUser) _botAvatar(),
        if (!isUser) const SizedBox(width: 10),

        Flexible(
          child: Column(
            crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                "$name · $time",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppColors.mainPaleBlue.withOpacity(0.25)
                      : AppColors.mainPaleBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.pointDustyNavy,
                  ),
                ),
              ),

              if (suggestions != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: suggestions!
                      .map(
                        (txt) => OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.pointDustyNavy.withOpacity(0.8),
                        ),
                      ),
                      child: Text(
                        txt,
                        style: const TextStyle(color: AppColors.pointDustyNavy),
                      ),
                    ),
                  )
                      .toList(),
                ),
              ],
            ],
          ),
        ),

        if (isUser) const SizedBox(width: 10),

        // 사용자 아바타
        if (isUser) _userAvatar(),
      ],
    );
  }

  // 상담원 아바타
  Widget _botAvatar() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.pointDustyNavy),
        image: const DecorationImage(
          image: AssetImage("images/chatboticon.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // 사용자 아바타
  Widget _userAvatar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.pointDustyNavy,
      ),
      child: const Icon(Icons.person, color: Colors.white),
    );
  }
}
