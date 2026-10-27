// Share an item: photos (uploaded to the API), title, description, category,
// condition and location. Blocks sale/price wording (anti-resell).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/constants.dart';
import '../../l10n/app_localizations.dart';
import '../../models/need.dart';
import '../../providers/user_provider.dart';
import '../../utils/helpers.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_button.dart';
import '../../config/dependencies.dart';

class CreatePostScreen extends StatefulWidget {
  /// When sharing in answer to someone's need, its requester is notified.
  final Need? forNeed;

  const CreatePostScreen({super.key, this.forNeed});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController();

  String _categoryId = AppCategories.all.first.id;
  String _condition = 'good';
  late String _district;
  final List<XFile> _photos = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _district = Provider.of<UserProvider>(context, listen: false).district;
    if (!AppDistricts.all.contains(_district)) _district = 'Colombo';
    final need = widget.forNeed;
    if (need != null) {
      _title.text = need.title;
      _categoryId = AppCategories.byId(need.categoryId).id;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    if (!Dependencies.items.photoUploadsEnabled) {
      showSnack(context,
          'Photo uploads are not available right now. You can post without photos.',
          error: true);
      return;
    }
    final picked = await Dependencies.items.pickImages();
    if (picked.isEmpty) return;
    setState(() {
      _photos.addAll(picked);
      if (_photos.length > AppConfig.maxItemImages) {
        _photos.removeRange(AppConfig.maxItemImages, _photos.length);
      }
    });
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final id = await Dependencies.items.createItem(
        title: _title.text,
        description: _description.text,
        categoryId: _categoryId,
        condition: _condition,
        district: _district,
        city: _city.text,
        photos: _photos,
        forNeed: widget.forNeed,
      );
      if (!mounted) return;
      showSnack(context, 'Your item is live! 🎉');
      context.pushReplacement('/item/$id');
    } catch (e) {
      if (!mounted) return;
      final msg = e is StateError
          ? e.message
          : e.toString().contains('permission-denied')
              ? 'Not allowed: check that your role is Donor/Both and the text has no prices.'
              : 'Could not post the item: $e';
      showSnack(context, msg, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.shareItem)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (widget.forNeed != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondaryBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Answering the need "${widget.forNeed!.title}". They will be notified when you post.',
                    style: const TextStyle(fontSize: 12, color: AppColors.brandPrimary),
                  ),
                ),
              _photoStrip(),
              const SizedBox(height: 20),
              AppTextField(
                controller: _title,
                label: 'Title',
                hint: 'e.g. Grade 10 science textbooks',
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.itemTitle,
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _description,
                label: 'Description',
                hint: 'Condition, size, pickup details…',
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.itemDescription,
              ),
              const SizedBox(height: 8),
              _label('Category'),
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
              _label('Condition'),
              Wrap(
                spacing: 8,
                children: [
                  for (final e in AppConditions.labels.entries)
                    ChoiceChip(
                      label: Text(e.value),
                      selected: _condition == e.key,
                      onSelected: (_) => setState(() => _condition = e.key),
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
                hint: 'e.g. Nugegoda',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.colorWarningBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Shareloop is for free giving. Posts mentioning prices or sales are blocked and can be reported.',
                  style: TextStyle(fontSize: 12, color: AppColors.colorWarningText),
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: _saving ? 'Posting…' : 'Post item',
                onPressed: _saving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      );

  Widget _photoStrip() {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_photos.length < AppConfig.maxItemImages)
            GestureDetector(
              onTap: _addPhotos,
              child: Container(
                width: 96,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondaryBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSelected),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo_outlined,
                        color: AppColors.brandPrimary),
                    const SizedBox(height: 4),
                    Text('${_photos.length}/${AppConfig.maxItemImages}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          for (var i = 0; i < _photos.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _PhotoPreview(file: _photos[i]),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _photos.removeAt(i)),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Shows a picked photo on every platform (reads bytes, no dart:io).
class _PhotoPreview extends StatelessWidget {
  final XFile file;

  const _PhotoPreview({required this.file});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(width: 96, height: 96, color: Colors.grey.shade200);
        }
        return Image.memory(snapshot.data!, width: 96, height: 96, fit: BoxFit.cover);
      },
    );
  }
}
