// Request an item: short message to the donor.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/item.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_button.dart';
import '../../config/dependencies.dart';

class CreateRequestScreen extends StatefulWidget {
  final Item item;

  const CreateRequestScreen({super.key, required this.item});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _message = TextEditingController();
  bool _sending = false;
  bool _agreed = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || !_formKey.currentState!.validate()) return;
    if (!_agreed) {
      showSnack(context, 'Please accept the declaration first.', error: true);
      return;
    }
    setState(() => _sending = true);
    try {
      final id = await Dependencies.requests.createRequest(
        item: widget.item,
        reason: _message.text,
        agreedNoResell: _agreed,
      );
      if (!mounted) return;
      showSnack(context, 'Request sent! The donor has been notified.');
      context.pushReplacement('/request/$id');
    } catch (e) {
      if (!mounted) return;
      final msg = e is StateError
          ? e.message
          : e.toString().contains('permission-denied')
              ? 'You already requested this item, or it is no longer available.'
              : 'Could not send the request: $e';
      showSnack(context, msg, error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Request item')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  ItemImage(
                    url: item.images.isEmpty ? null : item.images.first,
                    categoryId: item.categoryId,
                    height: 72,
                    width: 72,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${AppConditions.label(item.condition)} · ${item.district}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(AppLocalizations.of(context)!.reasonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              AppTextField(
                controller: _message,
                hint: 'The donor reads every reason before choosing who receives the item.',
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.requestMessage,
              ),
              const SizedBox(height: 8),
              const Text(
                'You can request each item once. Contact details are shared only if the donor selects you.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  AppLocalizations.of(context)!.antiResellDeclaration,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: _sending ? 'Sending…' : 'Send request',
                onPressed: _sending || !_agreed ? null : _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
