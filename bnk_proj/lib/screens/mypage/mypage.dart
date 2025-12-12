import 'package:flutter/material.dart';
import '../app_colors.dart';
import 'package:test_main/screens/mypage/review_write.dart';

/// 마이페이지 메인 화면
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   backgroundColor: AppColors.backgroundOffWhite,
      //   elevation: 0,
      //   leading: const BackButton(color: AppColors.pointDustyNavy),
      //   centerTitle: true,
      //   title: const Text(
      //     '마이페이지',
      //     style: TextStyle(
      //       color: AppColors.pointDustyNavy,
      //       fontWeight: FontWeight.w700,
      //     ),
      //   ),
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SizedBox(height: 60),
            _MyPageUserSummary(),
            SizedBox(height: 10),
            _MyPageShortcutGrid(),
            SizedBox(height: 34),
            // 필요하면 여기 아래에 다른 내용(배너, 추천 카드 등) 추가
          ],
        ),
      ),
    );
  }
}
/// ✅ Drawer(오른쪽 슬라이드)로 띄울 마이페이지 내용
class MyPageDrawer extends StatelessWidget {
  const MyPageDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ 닫기 버튼 (오른쪽 상단)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context), // drawer 닫기
                  ),
                ],
              ),


              const SizedBox(height: 10),


              const _MyPageUserSummary(),
              const SizedBox(height: 10),
              const _MyPageShortcutGrid(),
              SizedBox(
                width: double.infinity,           // ✅ 가로 꽉
                child: Image.asset(
                  'images/character_ant.png',
                  fit: BoxFit.fitWidth,           // ✅ 가로에 맞춰 꽉
                ),
              ),

              const _AllMenuSectionList(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 상단 사용자 요약 카드
class _MyPageUserSummary extends StatelessWidget {
  const _MyPageUserSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 8.0),
      //  left:12, top:0, right:12, bottom:8
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 왼쪽: 홍길동 >
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MyProfileScreen(),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '홍길동',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pointDustyNavy,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.black38,
                ),
              ],
            ),
          ),

          // 오른쪽: 환경설정
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MySettingsScreen(),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.settings_outlined,
                  size: 22,
                  color: Colors.black54,
                ),
                SizedBox(width: 4),
                Text(
                  '설정',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



class _MyPageShortcutGrid extends StatelessWidget {
  const _MyPageShortcutGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final shortcuts = <_ShortcutItem>[
      _ShortcutItem(
        icon: Icons.account_balance_wallet_outlined,
        label: '내 계좌',
        hasBadge: true,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MyAccountInfoScreen(),
            ),
          );
        },
      ),
      _ShortcutItem(
        icon: Icons.savings_outlined,
        label: '나의 외화예금',
        hasBadge: false,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MyFxDepositScreen(),
            ),
          );
        },
      ),
      _ShortcutItem(
        icon: Icons.pie_chart_outline,
        label: '보유 외화자산',
        hasBadge: false,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MyFxAssetScreen(),
            ),
          );
        },
      ),
      _ShortcutItem(
        icon: Icons.rate_review_outlined,
        label: '상품 리뷰 작성',
        hasBadge: false,
        onTap: () {
          Navigator.pushNamed(
            context,
            DepositReviewWriteScreen.routeName,
          );
        },
      ),
      _ShortcutItem(
        icon: Icons.verified_outlined,
        label: '내 신용정보',
        hasBadge: true,
        onTap: () {},
      ),
      _ShortcutItem(
        icon: Icons.badge_outlined,
        label: '모바일 신분증',
        hasBadge: false,
        onTap: () {},
      ),
      _ShortcutItem(
        icon: Icons.campaign_outlined,
        label: '공지사항',
        hasBadge: true,
        onTap: () {},
      ),
      _ShortcutItem(
        icon: Icons.lock_outline,
        label: '인증/보안',
        hasBadge: false,
        onTap: () {},
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shortcuts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final item = shortcuts[index];
        return _ShortcutIconButton(item: item);
      },
    );
  }
}
class _AllMenuSectionList extends StatelessWidget {
  const _AllMenuSectionList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _MenuSection(
          title: '외화예금',
          items: [
            _MenuItem('외화예금상품'),
            _MenuItem('외화예금안내'),
          ],
        ),
        _MenuSection(
          title: '외화송금',
          items: [
            _MenuItem('외화송금하기'),
            _MenuItem('외화송금안내'),
          ],
        ),
        _MenuSection(
          title: '환전',
          items: [
            _MenuItem('환전하기'),
            _MenuItem('환전 가능 통화'),
            _MenuItem('환전안내'),
          ],
        ),
        _MenuSection(
          title: '환율',
          items: [
            _MenuItem('환율조회'),
            _MenuItem('환전계산기'),
          ],
        ),
        _MenuSection(
          title: '고객센터',
          items: [
            _MenuItem('flobank소개'),
            _MenuItem('QnA'),
            _MenuItem('FAQ'),
            _MenuItem('이벤트'),
            _MenuItem('공지사항'),
            _MenuItem('뉴스리스트'),
          ],
        ),
      ],
    );
  }
}

class _MenuItem {
  final String label;
  final VoidCallback? onTap;
  final String? midAsset;
  const _MenuItem(this.label, {this.onTap, this.midAsset});
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ 타이틀: 작게/연하게
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),

          // ✅ 항목: 개별 둥근 타일로 쭉
          ...items.map((it) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MenuRow(
              label: it.label,
              onTap: it.onTap ?? () {},
              leadingIcon: _iconForLabel(it.label),
              midAsset: it.midAsset,
              badge: null, // 필요하면 'Beta'/'신규' 넣어
            ),
          )),
        ],
      ),
    );
  }

  static IconData _iconForLabel(String label) {
    if (label.contains('예금')) return Icons.savings_outlined;
    if (label.contains('송금')) return Icons.send_outlined;
    if (label.contains('환전')) return Icons.currency_exchange_outlined;
    if (label.contains('환율')) return Icons.show_chart_outlined;
    if (label.contains('계산기')) return Icons.calculate_outlined;
    if (label.contains('QnA') || label.contains('FAQ')) return Icons.help_outline;
    if (label.contains('공지')) return Icons.campaign_outlined;
    if (label.contains('뉴스')) return Icons.article_outlined;
    if (label.contains('이벤트')) return Icons.celebration_outlined;
    return Icons.circle_outlined;
  }
}


class _MenuRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData leadingIcon;
  final String? badge;
  final String? midAsset;

  const _MenuRow({
    required this.label,
    required this.onTap,
    required this.leadingIcon,
    this.badge,
    this.midAsset,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,                     // ✅ 흰색
          borderRadius: BorderRadius.circular(16), // ✅ 둥글게
        ),
        child: Row(
          children: [
            // ✅ 좌측 아이콘 원형
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFFF6F7F8),          // 아이콘 배경만 살짝 회색
                shape: BoxShape.circle,
              ),
              child: Icon(leadingIcon, size: 16, color: Colors.black87),
            ),
            const SizedBox(width: 12),

            if (midAsset != null) ...[
              Image.asset(
                midAsset!,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
            ],

            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),

            if (badge != null) _BadgeChip(badge!),

            // ✅ chevron(>) 제거
          ],
        ),
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String text;
  const _BadgeChip(this.text);

  @override
  Widget build(BuildContext context) {
    final isNew = text == '신규';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFFFEBEE) : const Color(0xFFEFF1F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isNew ? const Color(0xFFD32F2F) : Colors.black87,
        ),
      ),
    );
  }
}


class _ShortcutIconButton extends StatelessWidget {
  final _ShortcutItem item;

  const _ShortcutIconButton({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: item.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 둥근 카드 + 아이콘 + 뱃지
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.black.withOpacity(0.06),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    size: 30,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (item.hasBadge)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ShortcutItem {
  final IconData icon;
  final String label;
  final bool hasBadge;
  final VoidCallback? onTap;

  const _ShortcutItem({
    required this.icon,
    required this.label,
    required this.hasBadge,
    this.onTap,
  });
}


/// 공통 섹션 카드 (제목 + 설명 + 내용)
class _MyPageSection extends StatelessWidget {
  final String title;
  final String description;
  final Widget? child;          // ⬅️ nullable 로 변경
  final VoidCallback? onTap;

  const _MyPageSection({
    super.key,
    required this.title,
    required this.description,
    this.child,                 // ⬅️ 선택값
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contentWidgets = <Widget>[
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.pointDustyNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.black38,
            ),
        ],
      ),
    ];

    if (child != null) {
      contentWidgets.add(const SizedBox(height: 12));
      contentWidgets.add(child!);
    }

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: contentWidgets,
      ),
    );

    if (onTap == null) {
      return card;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: card,
    );
  }
}


/// 라벨/값 한 줄
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.pointDustyNavy,
          ),
        ),
      ],
    );
  }
}
// 나의 계좌정보 화면 //
class MyAccountInfoScreen extends StatelessWidget {
  const MyAccountInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.pointDustyNavy,
    );

    const cellStyle = TextStyle(
      fontSize: 13,
      color: Colors.black87,
    );

    // TODO: 나중에 실제 API로 교체
    final accounts = const <_AccountSummary>[
      _AccountSummary(
        name: '급여통장',
        accountNo: '123-456-789012',
        balance: '₩ 1,235,000',
      ),
      _AccountSummary(
        name: '생활비통장',
        accountNo: '123-456-789013',
        balance: '₩ 520,000',
      ),
      _AccountSummary(
        name: '적금통장',
        accountNo: '123-456-789014',
        balance: '₩ 3,000,000',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOffWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.pointDustyNavy),
        centerTitle: true,
        title: const Text(
          '나의 계좌정보',
          style: TextStyle(
            color: AppColors.pointDustyNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== 헤더 =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('계좌명', style: headerStyle),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('계좌번호', style: headerStyle),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('잔액', style: headerStyle),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text('이체', style: headerStyle),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ===== 데이터 행 =====
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: accounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final acc = accounts[index];

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // 계좌명
                      Expanded(
                        flex: 3,
                        child: Text(
                          acc.name,
                          style: cellStyle.copyWith(
                            color: AppColors.pointDustyNavy,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 계좌번호
                      Expanded(
                        flex: 3,
                        child: Text(
                          acc.accountNo,
                          style: cellStyle,
                        ),
                      ),
                      // 잔액
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            acc.balance,
                            style: cellStyle,
                          ),
                        ),
                      ),
                      // 이체 버튼
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _TransferButton(
                              onTap: () {
                                // TODO: 이체 화면으로 이동
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 나의 계좌정보 한 줄 데이터
class _AccountSummary {
  final String name;       // 계좌명
  final String accountNo;  // 계좌번호
  final String balance;    // 잔액 (표시용 문자열)

  const _AccountSummary({
    required this.name,
    required this.accountNo,
    required this.balance,
  });
}

/// 이체 버튼
class _TransferButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TransferButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          side: const BorderSide(color: Color(0xFF3D5C9B)),
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: const Color(0xFF3D5C9B),
        ),
        child: const Text(
          '이체',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
// 나의 외화예금 화면 //
class MyFxDepositScreen extends StatelessWidget {
  const MyFxDepositScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 나중에 실제 API에서 불러오기
    final fxDeposits = const <_FxDeposit>[
      _FxDeposit(
        productName: 'FLOBANK 외화정기예금',
        accountNo: '8888-72-0014-0001',
        balance: '₩ 1,000,000',
      ),
      _FxDeposit(
        productName: 'FLOBANK 외화정기예금',
        accountNo: '8888-72-0015-0001',
        balance: '\$ 1,000',
      ),
      _FxDeposit(
        productName: 'FLOBANK 외화정기예금',
        accountNo: '8888-72-0016-0001',
        balance: '¥ 100,000',
      ),
      _FxDeposit(
        productName: 'FLOBANK 외화정기예금',
        accountNo: '8888-72-0809-0001',
        balance: '€ 10,000',
      ),
      _FxDeposit(
        productName: 'FLOBANK 외화정기예금',
        accountNo: '8888-72-0810-0001',
        balance: '£ 5,000',
      ),
      _FxDeposit(
        productName: 'FLOBANK 외화 거치식 정기예금',
        accountNo: '8888-76-0812-0001',
        balance: '元 30,000',
      ),
    ];

    const headerStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.pointDustyNavy,
    );

    const cellStyle = TextStyle(
      fontSize: 13,
      color: Colors.black87,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOffWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.pointDustyNavy),
        centerTitle: true,
        title: const Text(
          '나의 외화예금',
          style: TextStyle(
            color: AppColors.pointDustyNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ===== 헤더 영역 =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('상품명', style: headerStyle),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('계좌번호', style: headerStyle),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('잔액', style: headerStyle),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.center,
                      child: Text('바로가기', style: headerStyle),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ===== 데이터 행들 =====
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fxDeposits.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final fx = fxDeposits[index];

                return Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      // 상품명
                      Expanded(
                        flex: 3,
                        child: Text(
                          fx.productName,
                          style: cellStyle.copyWith(
                            color: AppColors.pointDustyNavy,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // 계좌번호
                      Expanded(
                        flex: 3,
                        child: Text(
                          fx.accountNo,
                          style: cellStyle,
                        ),
                      ),

                      // 잔액
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            fx.balance,
                            style: cellStyle,
                          ),
                        ),
                      ),

                      // 바로가기 버튼 (조회 / 입금)
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown, // 공간 안으로 알아서 축소
                            child: Row(
                              children: [
                                _FxActionButton(
                                  label: '조회',
                                  onTap: () {
                                    // TODO
                                  },
                                ),
                                const SizedBox(width: 4),
                                _FxActionButton(
                                  label: '입금',
                                  onTap: () {
                                    // TODO
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
// 보유 외화자산 상세 화면 //
class MyFxAssetScreen extends StatelessWidget {
  const MyFxAssetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.pointDustyNavy,
    );

    const cellStyle = TextStyle(
      fontSize: 13,
      color: Colors.black87,
    );

    // TODO: 나중에 실제 API로 교체
    final assets = const <_FxAsset>[
      _FxAsset(currency: 'KRW', amount: '₩ 1,000,000', krwValue: '₩ 1,000,000'),
      _FxAsset(currency: 'USD', amount: '\$ 1,000', krwValue: '₩ 1,300,000'),
      _FxAsset(currency: 'JPY', amount: '¥ 100,000', krwValue: '₩ 900,000'),
      _FxAsset(currency: 'EUR', amount: '€ 5,000', krwValue: '₩ 7,000,000'),
      _FxAsset(currency: 'GBP', amount: '£ 2,000', krwValue: '₩ 3,400,000'),
      _FxAsset(currency: 'CHN', amount: '元 30,000', krwValue: '₩ 500,000'),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOffWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.pointDustyNavy),
        centerTitle: true,
        title: const Text(
          '보유 외화자산',
          style: TextStyle(
            color: AppColors.pointDustyNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text('통화', style: headerStyle),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('보유 수량', style: headerStyle),
                  ),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text('원화 환산 금액', style: headerStyle),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 데이터 행
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final a = assets[index];
                return Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          a.currency,
                          style: cellStyle.copyWith(
                            color: AppColors.pointDustyNavy,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          a.amount,
                          style: cellStyle,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            a.krwValue,
                            style: cellStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FxAsset {
  final String currency;  // 통화 (USD 등)
  final String amount;    // 보유 수량
  final String krwValue;  // 원화 환산 금액

  const _FxAsset({
    required this.currency,
    required this.amount,
    required this.krwValue,
  });
}

/// 외화예금 한 줄 데이터
class _FxDeposit {
  final String productName;
  final String accountNo;
  final String balance;

  const _FxDeposit({
    required this.productName,
    required this.accountNo,
    required this.balance,
  });
}

/// 조회 / 입금 작은 버튼
class _FxActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FxActionButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          side: const BorderSide(color: Color(0xFF3D5C9B)),
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: const Color(0xFF3D5C9B),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOffWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.pointDustyNavy),
        centerTitle: true,
        title: const Text(
          '개인정보',
          style: TextStyle(
            color: AppColors.pointDustyNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          '개인정보 화면 (추후 구현 예정)',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ),
    );
  }
}
class MySettingsScreen extends StatelessWidget {
  const MySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundOffWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.pointDustyNavy),
        centerTitle: true,
        title: const Text(
          '환경설정',
          style: TextStyle(
            color: AppColors.pointDustyNavy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          '환경설정 화면 (추후 구현 예정)',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}



