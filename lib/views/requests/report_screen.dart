// Report an item or user (spam, resell, fraud…). Admins review reports.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_button.dart';
import '../../config/dependencies.dart';

class ReportScreen extends StatefulWidget {
  final String targetType; // item | user
  final String targetId;
  final String label;

  const ReportScreen({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.label,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _details = TextEditingController();
  String _reason = 'spam';
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending || !_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final ok = await Dependencies.reports.submit(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: _reason,
        details: _details.text,
      );
      if (!mounted) return;
      showSnack(
        context,
        ok ? 'Report sent. Our admins will review it.' : 'You already reported this.',
        error: !ok,
      );
      context.pop();
    } catch (e) {
      if (mounted) showSnack(context, 'Could not send report: $e', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Text(widget.targetType == 'item' ? 'Report item' : 'Report user')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Reporting: ${widget.label}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Reason', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in ReportReasons.labels.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _reason == e.key,
                    onSelected: (_) => setState(() => _reason = e.key),
                    selectedColor: AppColors.tertiary,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _details,
              hint: 'What happened? (optional)',
              maxLines: 4,
              maxLength: 500,
              validator: Validators.reportDetails,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: _sending ? 'Sending…' : 'Send report',
              onPressed: _sending ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
