class PaySetting {
  const PaySetting({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.workSiteId,
    required this.workSiteName,
    required this.dailyWage,
    required this.taxRate,
    required this.taxAmount,
    required this.netDailyWage,
    required this.active,
  });

  final int id;
  final int employeeId;
  final String employeeName;
  final int workSiteId;
  final String workSiteName;
  final int dailyWage;
  final double taxRate;
  final int taxAmount;
  final int netDailyWage;
  final bool active;

  factory PaySetting.fromJson(Map<String, dynamic> json) {
    return PaySetting(
      id: json['id'] as int,
      employeeId: json['employeeId'] as int,
      employeeName: json['employeeName'] as String,
      workSiteId: json['workSiteId'] as int,
      workSiteName: json['workSiteName'] as String,
      dailyWage: (json['dailyWage'] as num).toInt(),
      taxRate: (json['taxRate'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num).toInt(),
      netDailyWage: (json['netDailyWage'] as num).toInt(),
      active: json['active'] as bool,
    );
  }

  String get dailyWageLabel => '${dailyWage.toString()}원';

  String get taxRateLabel => '${taxRate.toStringAsFixed(2)}%';

  String get taxAmountLabel => '${taxAmount.toString()}원';

  String get netDailyWageLabel => '${netDailyWage.toString()}원';
}