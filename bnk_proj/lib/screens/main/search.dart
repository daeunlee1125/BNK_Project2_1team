import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  // 검색 상태 관리
  bool _isSearching = false;
  String _query = "";

  late TabController _tabController;

  // 최근 검색어 데이터
  List<Map<String, String>> _recentSearches = [
    {"term": "엔화 환전", "date": "10.24"},
    {"term": "적금 금리", "date": "10.23"},
    {"term": "오사카 여행", "date": "10.22"},
    {"term": "달러 환율", "date": "10.20"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // 검색어 삭제
  void _removeSearchTerm(int index) {
    setState(() => _recentSearches.removeAt(index));
  }

  // 전체 삭제
  void _clearAll() {
    setState(() => _recentSearches.clear());
  }

  // 검색 실행
  void _doSearch(String text) {
    if (text.isEmpty) return;
    setState(() {
      _query = text;
      _isSearching = true;
      _recentSearches.insert(0, {"term": text, "date": "오늘"});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "검색어를 입력해주세요",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.black, fontSize: 16),
          onSubmitted: _doSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF3E5D9C)),
            onPressed: () => _doSearch(_searchController.text),
          ),
        ],
        bottom: _isSearching
            ? TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF3E5D9C),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3E5D9C),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "통합검색"),
            Tab(text: "상품"),
            Tab(text: "FAQ"),
            Tab(text: "약관"),
            Tab(text: "공지사항"),
            Tab(text: "이벤트"),
          ],
        )
            : null,
      ),
      body: _isSearching ? _buildSearchResultView() : _buildRecentSearchView(),
    );
  }

  // ---------------- [1] 검색 전 화면 ----------------
  Widget _buildRecentSearchView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ✅ 1. AI에게 물어보기 (심플한 둥근 테두리 버튼)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: InkWell(
              onTap: () {
                print("AI 채팅방 이동");
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30), // 둥근 모서리
                  border: Border.all(color: const Color(0xFF3E5D9C), width: 1.5), // 파란 테두리
                ),
                alignment: Alignment.center,
                child: const Text(
                  "AI에게 물어보기",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E5D9C), // 글씨색 파란색
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10), // 간격

          // ✅ 2. 최근 검색어 리스트
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "최근 검색어",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (_recentSearches.isNotEmpty)
                      GestureDetector(
                        onTap: _clearAll,
                        child: Text(
                          "전체삭제",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // 리스트 뷰
                _recentSearches.isEmpty
                    ? Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: Text(
                    "최근 검색 내역이 없습니다.",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentSearches.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _recentSearches[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item["term"]!,
                        style: const TextStyle(fontSize: 15, color: Colors.black87),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item["date"]!,
                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                            onPressed: () => _removeSearchTerm(index),
                          ),
                        ],
                      ),
                      onTap: () {
                        _searchController.text = item["term"]!;
                        _doSearch(item["term"]!);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- [2] 검색 결과 화면 (기존 동일) ----------------
  Widget _buildSearchResultView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildUnifiedSearchTab(),
        _buildSimpleListTab("상품 검색 결과"),
        _buildSimpleListTab("FAQ 검색 결과"),
        _buildSimpleListTab("약관 검색 결과"),
        _buildSimpleListTab("공지사항 검색 결과"),
        _buildSimpleListTab("이벤트 검색 결과"),
      ],
    );
  }

  Widget _buildUnifiedSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 15),
              children: [
                TextSpan(
                  text: '"$_query"',
                  style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: "에 대한 검색 결과가 총 "),
                const TextSpan(text: "29건", style: TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: " 검색되었습니다."),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          _buildSectionHeader("상품", 7),
          _buildProductItem("FLOBANK 외화정기예금", "여유자금을 일정기간 정해 예치하는 외화 정기예금"),
          _buildProductItem("FLOBANK 외화보통예금", "단기자금 운용에 적합한 외화 자유적립식 예금"),
          _buildProductItem("FLOBANK 외화슈퍼플러스 예금", "금리·환율·외환수수료 우대를 제공하는 자유적립식 외화 적금"),
          const SizedBox(height: 20),
          _buildSectionHeader("FAQ", 5),
          _buildFaqItem("외화예금은 어떻게 개설하나요?", "인터넷뱅킹 또는 가까운 지점 방문을 통해 외화예금을 개설하실 수 있습니다."),
          const SizedBox(height: 20),
          _buildSectionHeader("약관", 12),
          _buildTermsItem("외화예금거래기본약관 (v3)", "이 약관은 예금주와 FLOBANK(이하 '은행'이라 한다)과의 외화예금거래에 적용됩니다."),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$title ($count)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3E5D9C))),
          const Text("더보기", style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProductItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF3E5D9C))),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Q. $question", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3E5D9C))),
          const SizedBox(height: 4),
          Text(answer, style: const TextStyle(fontSize: 13, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildTermsItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF3E5D9C))),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSimpleListTab(String title) {
    return Center(child: Text(title));
  }
}