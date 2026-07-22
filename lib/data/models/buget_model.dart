class BudgetModel {
  final double monthlyBudget;

  const BudgetModel({required this.monthlyBudget});

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(monthlyBudget: (map['monthlyBudget'] as num?)?.toDouble() ?? 0);
  }

  Map<String, dynamic> toMap() => {'monthlyBudget': monthlyBudget};
}