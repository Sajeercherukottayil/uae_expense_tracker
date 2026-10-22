import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/expense_store.dart';
import '../utils/format.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _editFunds(BuildContext context) async {
    final store = StoreScope.read(context);
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _FundsDialog(initial: store.startingFunds),
    );
    if (value != null) await store.setStartingFunds(value);
  }

  Future<void> _pickVisaExpiry(BuildContext context) async {
    final store = StoreScope.read(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      helpText: 'Visa expiry date',
      initialDate: store.visaExpiry ?? now.add(const Duration(days: 30)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) await store.setVisaExpiry(picked);
  }

  Future<void> _clearAll(BuildContext context) async {
    final store = StoreScope.read(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
            'This deletes every expense and your settings. It cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete all')),
        ],
      ),
    );
    if (confirmed == true) await store.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final visa = store.visaExpiry;
    final visaDays = store.visaDaysLeft;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Available funds'),
            subtitle: Text(store.startingFunds > 0
                ? aed(store.startingFunds)
                : 'The money you have for this trip'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _editFunds(context),
          ),
          ListTile(
            leading: const Icon(Icons.event_outlined),
            title: const Text('Visa expiry date'),
            subtitle: Text(visa == null
                ? 'Not set'
                : '${dayFormat.format(visa)} · '
                    '${visaDays! < 0 ? 'expired' : '$visaDays days left'}'),
            trailing: visa == null
                ? const Icon(Icons.edit_outlined)
                : IconButton(
                    tooltip: 'Remove',
                    onPressed: () => store.setVisaExpiry(null),
                    icon: const Icon(Icons.close)),
            onTap: () => _pickVisaExpiry(context),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
            title: Text('Clear all data', style: TextStyle(color: scheme.error)),
            onTap: () => _clearAll(context),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Your data is stored only on this phone.',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _FundsDialog extends StatefulWidget {
  const _FundsDialog({required this.initial});

  final double initial;

  @override
  State<_FundsDialog> createState() => _FundsDialogState();
}

class _FundsDialogState extends State<_FundsDialog> {
  late final _controller = TextEditingController(
      text: widget.initial > 0 ? widget.initial.toStringAsFixed(0) : '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() =>
      Navigator.pop(context, double.tryParse(_controller.text) ?? 0);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Available funds'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
        ],
        decoration: const InputDecoration(
          prefixText: 'AED ',
          helperText: 'Total money you have for your stay',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
