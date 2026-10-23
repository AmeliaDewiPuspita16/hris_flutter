import 'package:flutter/material.dart';

import '../../../../../../../core/theme/app_colors.dart';
import '../../domain/approve_request_item.dart';

/// Konfirmasi Reject di tab Approve Request, dengan alasan opsional
/// (maks 1000 karakter — batas server untuk `reason`).
///
/// Mengembalikan alasan yang diketik (boleh string kosong) bila HOD
/// menekan Reject, atau null bila dibatalkan.
Future<String?> showItRequestRejectDialog(
  BuildContext context,
  ApproveRequestItem item,
) {
  return showDialog<String>(
    context: context,
    builder: (_) => _RejectDialog(item: item),
  );
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.item});

  final ApproveRequestItem item;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject request?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.item.requesterName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.item.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              maxLength: 1000,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_reasonController.text),
          style: TextButton.styleFrom(foregroundColor: AppColors.rejected),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
