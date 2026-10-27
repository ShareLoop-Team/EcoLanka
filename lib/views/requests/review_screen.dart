// Leave a 1–5 star review after a completed donation.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../models/request.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/rating_widget.dart';
import '../../config/dependencies.dart';

class ReviewScreen extends StatefulWidget {
  final ShareRequest request;

  const ReviewScreen({super.key, required this.request});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _comment = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await Dependencies.reviews.leaveReview(
        request: widget.request,
        rating: _rating,
        comment: _comment.text,
      );
      if (!mounted) return;
      showSnack(context, 'Thanks for your review!');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('permission-denied')
          ? 'You have already reviewed this exchange.'
          : 'Could not save the review: $e';
      showSnack(context, msg, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iAmDonor = widget.request.donorId == Dependencies.auth.currentUid;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Leave a review')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'How was your experience with the ${iAmDonor ? 'requester' : 'donor'}?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              widget.request.itemTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            StarRatingInput(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _comment,
              hint: 'Optional comment (on time? friendly? item as described?)',
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              validator: Validators.reviewComment,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: _saving ? 'Saving…' : 'Submit review',
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
