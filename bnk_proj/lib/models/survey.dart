int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  return int.tryParse(value.toString()) ?? fallback;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  return int.tryParse(value.toString());
}

class SurveyOption {
  final int optId;
  final String optCode;
  final String optText;
  final String? optValue;
  final int optOrder;

  const SurveyOption({
    required this.optId,
    required this.optCode,
    required this.optText,
    required this.optValue,
    required this.optOrder,
  });

  factory SurveyOption.fromJson(Map<String, dynamic> json) {
    return SurveyOption(
      optId: _toInt(json['optId']),
      optCode: json['optCode']?.toString() ?? '',
      optText: json['optText']?.toString() ?? '',
      optValue: json['optValue']?.toString(),
      optOrder: _toInt(json['optOrder']),
    );
  }
}

class SurveyQuestion {
  final int qId;
  final int qNo;
  final String qKey;
  final String qText;
  final String qType;
  final String isRequired;
  final int? maxSelect;
  final List<SurveyOption> options;

  const SurveyQuestion({
    required this.qId,
    required this.qNo,
    required this.qKey,
    required this.qText,
    required this.qType,
    required this.isRequired,
    required this.maxSelect,
    required this.options,
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = (json['options'] as List<dynamic>? ?? []);
    return SurveyQuestion(
      qId: _toInt(json['qId']),
      qNo: _toInt(json['qNo']),
      qKey: json['qKey']?.toString() ?? '',
      qText: json['qText']?.toString() ?? '',
      qType: json['qType']?.toString() ?? '',
      isRequired: json['isRequired']?.toString() ?? 'N',
      maxSelect: _toNullableInt(json['maxSelect']),
      options: rawOptions
          .map((e) => SurveyOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SurveyDetail {
  final int surveyId;
  final String title;
  final String? description;
  final List<SurveyQuestion> questions;

  const SurveyDetail({
    required this.surveyId,
    required this.title,
    required this.description,
    required this.questions,
  });

  factory SurveyDetail.fromJson(Map<String, dynamic> json) {
    final rawQuestions = (json['questions'] as List<dynamic>? ?? []);
    return SurveyDetail(
      surveyId: _toInt(json['surveyId']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      questions: rawQuestions
          .map((e) => SurveyQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
