class SettingsModel {
  final int id;
  final double piggyBank;
  final double owing;
  final String lastProcessedMonth;

  SettingsModel({
    required this.id,
    required this.piggyBank,
    required this.owing,
    required this.lastProcessedMonth,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'piggy_bank': piggyBank,
    'owing': owing,
    'last_processed_month': lastProcessedMonth,
  };

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      id: map['id'],
      piggyBank: (map['piggy_bank'] ?? 0).toDouble(),
      owing: (map['owing'] ?? 0).toDouble(),
      lastProcessedMonth: map['last_processed_month'] ?? "",
    );
  }
}
