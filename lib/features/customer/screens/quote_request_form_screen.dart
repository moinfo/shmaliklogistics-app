import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_client.dart';
import '../../../core/ui/typography.dart';
import '../../../core/ui/ui_kit.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/colors.dart';
import '../../../core/utils/formatters.dart';
import '../customer_service.dart';
import 'customer_widgets.dart';

/// Form to submit a new quote request. Pops with `true` on success so the
/// caller can refresh its list and show a success snackbar.
class QuoteRequestFormScreen extends StatefulWidget {
  final CustomerService service;

  const QuoteRequestFormScreen({super.key, required this.service});

  @override
  State<QuoteRequestFormScreen> createState() => _QuoteRequestFormScreenState();
}

class _QuoteRequestFormScreenState extends State<QuoteRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _volumeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _preferredDate;
  bool _saving = false;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _descCtrl.dispose();
    _weightCtrl.dispose();
    _volumeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _preferredDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.service.submitQuoteRequest(
        routeFrom: _fromCtrl.text.trim(),
        routeTo: _toCtrl.text.trim(),
        cargoDescription: _descCtrl.text.trim(),
        cargoWeightKg:
            _weightCtrl.text.trim().isEmpty ? null : double.tryParse(_weightCtrl.text.trim()),
        cargoVolumeM3:
            _volumeCtrl.text.trim().isEmpty ? null : int.tryParse(_volumeCtrl.text.trim()),
        preferredDate: _preferredDate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: kDanger),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to submit request.'), backgroundColor: kDanger),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant(context),
      body: Column(
        children: [
          const CustomerDetailHeader(title: 'Request a Quote'),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  Text(
                    'Tell us about your shipment and our team will get back to you with a quote.',
                    style: AppType.body(13, color: kMuted, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  RevealOnLoad(
                    delayMs: 0,
                    child: AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Shipment Details',
                          eyebrow: 'New request',
                          icon: Icons.local_shipping_rounded,
                          accent: ModuleAccent.brand,
                        ),
                        _Field(
                          controller: _fromCtrl,
                          label: 'Origin *',
                          hint: 'e.g. Dar es Salaam',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        _Field(
                          controller: _toCtrl,
                          label: 'Destination *',
                          hint: 'e.g. Lusaka',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        _Field(
                          controller: _descCtrl,
                          label: 'Cargo description *',
                          hint: 'What are you shipping?',
                          minLines: 2,
                          maxLines: 4,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _Field(
                                controller: _weightCtrl,
                                label: 'Weight (kg)',
                                hint: '0',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _Field(
                                controller: _volumeCtrl,
                                label: 'Volume (m³)',
                                hint: '0',
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _DateField(
                          label: 'Preferred date (optional)',
                          value: _preferredDate,
                          onTap: _pickDate,
                          onClear:
                              _preferredDate != null ? () => setState(() => _preferredDate = null) : null,
                        ),
                        const SizedBox(height: 14),
                        _Field(
                          controller: _notesCtrl,
                          label: 'Notes (optional)',
                          hint: 'Anything else we should know?',
                          minLines: 2,
                          maxLines: 4,
                        ),
                      ],
                    ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  RevealOnLoad(
                    delayMs: 90,
                    child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ModuleAccent.brand.base,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: ModuleAccent.brand.base.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Submit Request',
                              style: AppType.body(15, weight: FontWeight.w700)),
                    ),
                  ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceVariant(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateField({required this.label, required this.value, required this.onTap, this.onClear});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surfaceVariant(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 16, color: kMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value != null ? formatDate(value) : 'Select a date',
                style: AppType.body(
                  14,
                  color: value != null ? AppColors.textPrimary(context) : kMuted,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded, size: 18, color: kMuted),
              ),
          ],
        ),
      ),
    );
  }
}
