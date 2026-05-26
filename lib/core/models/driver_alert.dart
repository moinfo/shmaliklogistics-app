class DriverAlert {
  final String id;
  final String kind;
  final String severity;
  final String title;
  final String message;
  final String href;
  final String cta;

  const DriverAlert({
    required this.id,
    required this.kind,
    required this.severity,
    required this.title,
    required this.message,
    required this.href,
    required this.cta,
  });

  factory DriverAlert.fromJson(Map<String, dynamic> j) => DriverAlert(
        id: j['id'] as String? ?? '',
        kind: j['kind'] as String? ?? '',
        severity: j['severity'] as String? ?? 'info',
        title: j['title'] as String? ?? '',
        message: j['message'] as String? ?? '',
        href: j['href'] as String? ?? '',
        cta: j['cta'] as String? ?? '',
      );

  bool get isCritical => severity == 'critical';
  bool get isWarning => severity == 'warning';
  bool get isInfo => severity == 'info';
}

class AlertBundle {
  final List<DriverAlert> items;
  final int count;
  final bool hasAlert;

  const AlertBundle({
    required this.items,
    required this.count,
    required this.hasAlert,
  });

  factory AlertBundle.fromJson(Map<String, dynamic> j) => AlertBundle(
        items: (j['items'] as List)
            .map((e) => DriverAlert.fromJson(e as Map<String, dynamic>))
            .toList(),
        count: (j['count'] as num).toInt(),
        hasAlert: j['has_alert'] as bool? ?? false,
      );

  factory AlertBundle.empty() =>
      const AlertBundle(items: [], count: 0, hasAlert: false);
}
