import 'package:flutter/material.dart';
import '../../../home/data/models/platform_feature.dart';

class AddFundDialog extends StatefulWidget {
  final Function(PlatformFeature) onAdd;

  const AddFundDialog({super.key, required this.onAdd});

  @override
  State<AddFundDialog> createState() => _AddFundDialogState();
}

class _AddFundDialogState extends State<AddFundDialog> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Fund'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Fund Name'),
          ),
          TextField(
            controller: _subtitleController,
            decoration: const InputDecoration(labelText: 'Fund Description'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty && _subtitleController.text.isNotEmpty) {
              final newFund = PlatformFeature(
                title: _titleController.text,
                subtitle: _subtitleController.text,
                icon: Icons.account_balance,
                accentColor: const Color(0xFF1E5CFF),
              );
              widget.onAdd(newFund);
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }
}
