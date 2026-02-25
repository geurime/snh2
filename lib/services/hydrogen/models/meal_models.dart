/// 오늘의 식사
class MealData {
  final String? lunch;
  final String? dinner;

  MealData({this.lunch, this.dinner});

  factory MealData.fromJson(Map<String, dynamic> json) {
    return MealData(
      lunch: json['lunch'],
      dinner: json['dinner'],
    );
  }
}
