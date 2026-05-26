import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  return 'TZS ${NumberFormat('#,###').format(amount)}';
}

String formatDate(DateTime? date) {
  if (date == null) return '—';
  return DateFormat('dd MMM yyyy').format(date);
}

String formatDateTime(DateTime dt) {
  return DateFormat('dd MMM yyyy, HH:mm').format(dt.toLocal());
}

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}