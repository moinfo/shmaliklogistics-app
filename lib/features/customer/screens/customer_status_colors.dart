import 'package:flutter/material.dart';

/// Status colours for customer-facing invoice records.
Color invoiceStatusColor(String status) {
  switch (status) {
    case 'draft':
      return const Color(0xFF94A3B8);
    case 'sent':
      return const Color(0xFF60A5FA);
    case 'partial':
      return const Color(0xFFF59E0B);
    case 'paid':
      return const Color(0xFF22C55E);
    case 'overdue':
      return const Color(0xFFEF4444);
    case 'cancelled':
      return const Color(0xFF475569);
    default:
      return const Color(0xFF94A3B8);
  }
}

/// Status colours for cargo/shipment records.
Color cargoStatusColor(String status) {
  switch (status) {
    case 'registered':
      return const Color(0xFF64748B);
    case 'loaded':
      return const Color(0xFFA78BFA);
    case 'in_transit':
      return const Color(0xFF3B82F6);
    case 'at_border':
      return const Color(0xFFF59E0B);
    case 'cleared':
      return const Color(0xFF06B6D4);
    case 'delivered':
      return const Color(0xFF22C55E);
    case 'cancelled':
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFF64748B);
  }
}

/// Status colours for portal quote requests.
Color quoteStatusColor(String status) {
  switch (status) {
    case 'pending':
      return const Color(0xFFF59E0B);
    case 'reviewed':
      return const Color(0xFF3B82F6);
    case 'quoted':
      return const Color(0xFF22C55E);
    case 'cancelled':
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFF94A3B8);
  }
}
