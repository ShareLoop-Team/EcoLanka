// Post a need ("Item Requests" module): what you need + the reason,
// with the mandatory anti-resell declaration.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../config/dependencies.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/user_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_button.dart';

class CreateNeedScreen extends StatefulWidget {
  const CreateNeedScreen({super.key});

  @override
  State<CreateNeedScreen> createState() => _CreateNeedScreenState();
}

class _CreateNeedScreenState extends State<CreateNeedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _reason = TextEditingController();
  final _city = TextEditingController();
  String _categoryId = AppCategories.all.first.id;
  late String _district;
  bool _agreed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _district = Provider.of<UserProvider>(context, listen: false).district;
    if (!AppDistricts.all.contains(_district)) _district = 'Colombo';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _reason.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (!_agreed) {
      showSnack(context, 'Please accept the declaration first.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await Dependencies.needs.createNeed(
        title: _title.text,
        description: _description.text,
        reason: _reason.text,
        categoryId: _categoryId,
        district: _district,
        city: _city.text,
        agreedNoResell: _agreed,
      );
      if (!mounted) return;
      showSnack(context, 'Your need is posted. Donors nearby can now see it.');
      context.pushReplacement('/need/$id');
    } catch (e) {
      if (!mounted) return;
      final msg = e is StateError
          ? e.message
          : e.toString().contains('permission-denied')
              ? 'Not allowed: check your role is Requester or Both.'
              : 'Could not post: $e';
      showSnack(context, msg, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(t.postNeed)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              AppTextField(
                controller: _title,
                label: 'What do you need?',
                hint: 'e.g. Grade 10 science textbook',
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.needTitle,
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _description,
                label: 'Details (optional)',
                hint: 'Size, edition, quantity…',
                maxLines: 3,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _reason,
                label: t.reasonLabel,
                hint: 'Donors read this to decide who to help.',
                maxLines: 3,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.requestMessage,
              ),
              const SizedBox(height: 8),
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in AppCategories.all)
                    ChoiceChip(
                      avatar: Icon(c.icon, size: 16),
                      label: Text(c.name),
                      selected: _categoryId == c.id,
                      onSelected: (_) => setState(() => _categoryId = c.id),
                      selectedColor: AppColors.tertiary,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _district,
                decoration: const InputDecoration(labelText: 'District'),
                items: [
                  for (final d in AppDistricts.all)
                    DropdownMenuItem(value: d, child: Text(d)),
                ],
                onChanged: (v) => setState(() => _district = v ?? _district),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _city,
                label: 'City / area (optional)',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(t.antiResellDeclaration,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: _saving ? 'Posting…' : t.postNeed,
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
