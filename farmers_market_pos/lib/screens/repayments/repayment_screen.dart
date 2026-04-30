import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farmer_provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_config.dart';

class RepaymentScreen extends ConsumerStatefulWidget {
  const RepaymentScreen({super.key});
  @override
  ConsumerState<RepaymentScreen> createState() => _State();
}

class _State extends ConsumerState<RepaymentScreen> {
  final _kgCtrl       = TextEditingController();
  final _rateCtrl     = TextEditingController(text: AppConfig.defaultCommodityRate.toString());
  final _notesCtrl    = TextEditingController();
  String _commodity   = 'cacao';
  bool _loading       = false;
  String? _error;
  Map<String, dynamic>? _result;
  double _fcfaPreview = 0;

  @override
  void dispose() {
    _kgCtrl.dispose(); _rateCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final kg   = double.tryParse(_kgCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? AppConfig.defaultCommodityRate;
    setState(() => _fcfaPreview = kg * rate);
  }

  Future<void> _submit() async {
    final farmer = ref.read(selectedFarmerProvider);
    if (farmer == null) {
      setState(() => _error = 'Veuillez sélectionner un agriculteur');
      return;
    }
    final kg   = double.tryParse(_kgCtrl.text);
    final rate = double.tryParse(_rateCtrl.text);
    if (kg == null || kg <= 0) {
      setState(() => _error = 'Quantité invalide');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.createRepayment(
        farmerId:     farmer.id,
        kgReceived:   kg,
        commodity:    _commodity,
        rateOverride: rate,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      setState(() { _result = res; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmer = ref.watch(selectedFarmerProvider);
    final fmt    = NumberFormat.decimalPattern('fr');

    // Success state
    if (_result != null) {
      final credited = (_result!['total_fcfa_credited'] as num).toDouble();
      final remaining = (_result!['remaining_fcfa'] as num? ?? 0).toDouble();
      return Scaffold(
        appBar: AppBar(title: const Text('Remboursement')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 72),
              const SizedBox(height: 16),
              const Text('Remboursement enregistré!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Crédit appliqué: ${fmt.format(credited.toInt())} FCFA',
                  style: const TextStyle(fontSize: 16)),
              if (remaining > 0)
                Text('Excédent non appliqué: ${fmt.format(remaining.toInt())} FCFA',
                    style: const TextStyle(color: Colors.orange)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Retour à l\'accueil'),
              ),
            ]),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Remboursement Cacao/Café')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Farmer
          Card(
            color: farmer == null
                ? Colors.orange.shade50
                : AppTheme.primary.withOpacity(0.06),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Icon(Icons.person,
                  color: farmer == null ? Colors.orange : AppTheme.primary),
              title: Text(
                farmer == null ? 'Sélectionner un agriculteur' : farmer.fullName,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: farmer == null ? Colors.orange : null),
              ),
              subtitle: farmer != null ? Text(farmer.identifier) : null,
              trailing: TextButton(
                onPressed: () => context.push('/farmers'),
                child: Text(farmer == null ? 'Choisir' : 'Changer'),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Commodity type
          Text('Type de produit',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: ['cacao', 'cafe', 'coton', 'autre'].map((c) {
            return ChoiceChip(
              label: Text(c),
              selected: _commodity == c,
              onSelected: (_) => setState(() => _commodity = c),
            );
          }).toList()),
          const SizedBox(height: 20),

          // Quantity
          Text('Quantité reçue (kg)',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _kgCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _updatePreview(),
            decoration: const InputDecoration(
              hintText: 'Ex: 52.5',
              suffixText: 'kg',
              prefixIcon: Icon(Icons.scale_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Rate
          Text('Taux (FCFA/kg)',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _rateCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => _updatePreview(),
            decoration: const InputDecoration(
              suffixText: 'FCFA/kg',
              prefixIcon: Icon(Icons.price_change_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Preview
          if (_fcfaPreview > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Valeur estimée:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '${fmt.format(_fcfaPreview.toInt())} FCFA',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.primary),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Notes
          TextFormField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes (optionnel)',
              prefixIcon: Icon(Icons.note_outlined),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          ],
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_fcfaPreview > 0
                      ? 'Confirmer — ${fmt.format(_fcfaPreview.toInt())} FCFA'
                      : 'Enregistrer le remboursement'),
            ),
          ),
        ]),
      ),
    );
  }
}
