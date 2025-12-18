class TermsDocument {
  final int? id;
  final int? cate;
  final int? order;
  final String title;
  final int version;
  final String? regDate;
  final String filePath;
  final String content;
  final String downloadUrl;

  const TermsDocument({
    required this.id,
    required this.cate,
    required this.order,
    required this.title,
    required this.version,
    required this.regDate,
    required this.filePath,
    required this.content,
    required this.downloadUrl,
  });

  factory TermsDocument.fromJson(Map<String, dynamic> json, String baseUrl) {
    final rawFile = json['file']?.toString() ?? '';
    final backendUrl = json['downloadUrl']?.toString();
    final fullUrl = (backendUrl != null && backendUrl.isNotEmpty)
        ? Uri.parse(backendUrl).toString()
        : _resolveFileUrl(rawFile, baseUrl);

    return TermsDocument(
      id: int.tryParse(json['histId']?.toString() ?? ''),
      cate: int.tryParse(json['cate']?.toString() ?? ''),
      order: int.tryParse(json['order']?.toString() ?? ''),
      title: json['title']?.toString() ?? '약관',
      version: int.tryParse(json['version']?.toString() ?? '') ?? 1,
      regDate: json['regDate']?.toString(),
      filePath: rawFile,
      content: json['content']?.toString() ?? '',
      downloadUrl: fullUrl,
    );
  }

  static String _resolveFileUrl(String filePath, String baseUrl) {
    final trimmed = filePath.trim();
    if (trimmed.isEmpty) return '';

    // 절대 URL 이면 그대로 사용하되, 잘못된 공백 등을 제거한다.
    final absolute = Uri.tryParse(trimmed);
    if (absolute != null && absolute.hasScheme) {
      return absolute.toString();
    }

    // 상대 경로를 안전하게 인코딩한 뒤 baseUrl과 병합한다.
    final normalizedSegments = trimmed
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map(Uri.encodeComponent)
        .toList();

    // 기본 경로가 제공되지 않았다면 terms 디렉터리를 붙인다.
    if (!trimmed.startsWith('/')) {
      normalizedSegments.insertAll(0, ['uploads', 'terms']);
    }

    final base = Uri.parse(baseUrl);
    final mergedSegments = <String>[
      ...base.pathSegments.where((s) => s.isNotEmpty),
      ...normalizedSegments,
    ];

    return base.replace(pathSegments: mergedSegments).toString();
  }
}