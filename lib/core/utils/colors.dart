import 'package:flutter/material.dart';

const kPrimary = Color(0xFF1565C0);   // Trans-Mas blue
const kAccent  = Color(0xFF0288D1);
const kBg      = Color(0xFFF5F7FA);
const kCard    = Colors.white;
const kSuccess = Color(0xFF22C55E);
const kWarning = Color(0xFFF59E0B);
const kDanger  = Color(0xFFEF4444);
const kMuted   = Color(0xFF64748B);

Color statusColor(String status) {
  switch (status) {
    case 'planned':    return const Color(0xFF94A3B8);
    case 'loading':    return const Color(0xFFF59E0B);
    case 'in_transit': return const Color(0xFF3B82F6);
    case 'at_border':  return const Color(0xFF8B5CF6);
    case 'delivered':  return const Color(0xFF22C55E);
    case 'completed':  return const Color(0xFF10B981);
    case 'cancelled':  return const Color(0xFFEF4444);
    case 'ok':         return const Color(0xFF22C55E);
    case 'issue':      return const Color(0xFFF59E0B);
    case 'emergency':  return const Color(0xFFEF4444);
    default:           return const Color(0xFF94A3B8);
  }
}