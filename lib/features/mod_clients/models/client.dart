import 'package:flutter/material.dart';

/// Light billing summary returned by the detail endpoint.
class ClientStats {
  final int quotes;
  final int invoices;
  final double totalBilled;

  ClientStats({
    this.quotes = 0,
    this.invoices = 0,
    this.totalBilled = 0,
  });

  factory ClientStats.fromJson(Map<String, dynamic> j) => ClientStats(
        quotes: int.tryParse((j['quotes'] ?? 0).toString()) ?? 0,
        invoices: int.tryParse((j['invoices'] ?? 0).toString()) ?? 0,
        totalBilled: double.tryParse((j['total_billed'] ?? 0).toString()) ?? 0,
      );
}

/// A client (`clients` row).
///
/// The list endpoint returns a flat summary (`name`, `company_name`, `status`,
/// `email`, `phone`, `tin_number`); the detail endpoint adds the alternate
/// phone, address, VRN, notes and a billing `stats` block. [Client.fromJson]
/// handles both. The `portal_password` is hidden server-side and never present.
class Client {
  final int id;
  final String name;
  final String? companyName;
  final String status;
  final String statusLabel;
  final String? statusColorHex;
  final String? email;
  final String? phone;
  final String? tinNumber;

  // Detail-only fields.
  final String? phoneAlt;
  final String? address;
  final String? vrnNumber;
  final String? notes;
  final DateTime? createdAt;
  final ClientStats? stats;

  Client({
    required this.id,
    required this.name,
    this.companyName,
    required this.status,
    required this.statusLabel,
    this.statusColorHex,
    this.email,
    this.phone,
    this.tinNumber,
    this.phoneAlt,
    this.address,
    this.vrnNumber,
    this.notes,
    this.createdAt,
    this.stats,
  });

  factory Client.fromJson(Map<String, dynamic> j) {
    final status = (j['status'] ?? 'active').toString();
    return Client(
      id: j['id'] ?? 0,
      name: (j['name'] ?? 'Unknown').toString(),
      companyName: j['company_name'],
      status: status,
      statusLabel: (j['status_label'] ?? _titleCase(status)).toString(),
      statusColorHex: j['status_color']?.toString(),
      email: j['email'],
      phone: j['phone'],
      tinNumber: j['tin_number'],
      phoneAlt: j['phone_alt'],
      address: j['address'],
      vrnNumber: j['vrn_number'],
      notes: j['notes'],
      createdAt: _date(j['created_at']),
      stats: j['stats'] is Map<String, dynamic>
          ? ClientStats.fromJson(j['stats'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static String _titleCase(String s) => s
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  /// Status colour parsed from the backend hex (falls back to a slate grey).
  Color get statusColor {
    final hex = statusColorHex;
    if (hex == null) return const Color(0xFF475569);
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return const Color(0xFF475569);
    return Color(cleaned.length <= 6 ? 0xFF000000 | value : value);
  }

  bool get hasCompany => companyName != null && companyName!.trim().isNotEmpty;
}
