// Avatar + name (+ optional district) for the owner of an item or need,
// as on the Figma "Community Requests" and "Explore" cards.

import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/dependencies.dart';
import '../models/user.dart';
import 'app_widgets.dart';

class PersonRow extends StatefulWidget {
  final String uid;
  final bool showDistrict;

  const PersonRow({super.key, required this.uid, this.showDistrict = true});

  @override
  State<PersonRow> createState() => _PersonRowState();
}

class _PersonRowState extends State<PersonRow> {
  late final Stream<AppUser?> _user = Dependencies.users.watchUser(widget.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _user,
      builder: (context, snapshot) {
        final u = snapshot.data;
        final name = u?.displayName ?? '';
        return Row(
          children: [
            UserAvatar(name: name, photoUrl: u?.photoUrl, radius: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? '…' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      letterSpacing: 0.14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (widget.showDistrict && u != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            u.district,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
