// Edit name, district, role and profile photo.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_role.dart';
import '../../models/user.dart';
import '../../providers/user_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_button.dart';
import '../../config/dependencies.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _district;
  late String _role;
  String? _photoUrl;
  bool _saving = false;
  bool _uploading = false;
  bool _locating = false;
  AppUser? _profile;

  @override
  void initState() {
    super.initState();
    _profile = Provider.of<UserProvider>(context, listen: false).profile;
    _name = TextEditingController(text: _profile?.displayName ?? '');
    _district = _profile?.district ?? 'Colombo';
    if (!AppDistricts.all.contains(_district)) _district = 'Colombo';
    _role = _profile?.role ?? 'both';
    _photoUrl = _profile?.photoUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    if (!Dependencies.users.photoUploadsEnabled) {
      showSnack(context, 'Photo uploads are not available right now.', error: true);
      return;
    }
    final file = await Dependencies.users.pickPhoto();
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final url = await Dependencies.users.uploadProfilePhoto(file);
      if (mounted) setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) showSnack(context, 'Upload failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final district = await Dependencies.users.detectNearestDistrict();
      if (!mounted) return;
      setState(() => _district = district);
      showSnack(context, 'District set to $district');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final fields = <String, dynamic>{
        'displayName': _name.text.trim(),
        'district': _district,
        'photoUrl': _photoUrl,
      };
      if (_role != 'admin') fields['role'] = _role;
      await Dependencies.users.updateProfile(fields);
      if (!mounted) return;
      showSnack(context, 'Profile updated');
      context.pop();
    } catch (e) {
      if (mounted) showSnack(context, 'Could not save: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  UserAvatar(name: _name.text, photoUrl: _photoUrl, radius: 48),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.brandPrimary,
                      child: _uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              icon: const Icon(Icons.camera_alt, color: Colors.white),
                              onPressed: _changePhoto,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _name,
              label: 'Full name',
              textCapitalization: TextCapitalization.words,
              validator: Validators.displayName,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_district),
              initialValue: _district,
              decoration: const InputDecoration(labelText: 'District'),
              items: [
                for (final d in AppDistricts.all)
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: (v) => setState(() => _district = v ?? _district),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _locating ? null : _useMyLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(AppLocalizations.of(context)!.useMyLocation),
              ),
            ),
            const SizedBox(height: 12),
            if (_role != 'admin') ...[
              const Text('I want to', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final role in UserRole.selectable)
                    ChoiceChip(
                      label: Text(role.label),
                      tooltip: role.description,
                      selected: _role == role.id,
                      onSelected: (_) => setState(() => _role = role.id),
                      selectedColor: AppColors.tertiary,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            PrimaryButton(
              text: _saving ? 'Saving…' : 'Save changes',
              onPressed: _saving || _uploading ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
