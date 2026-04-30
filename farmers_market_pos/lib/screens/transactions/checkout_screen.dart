import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/product_provider.dart';
import '../../providers/farmer_provider.dart';
import '../../config/app_theme.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _State();
}

class _State extends ConsumerState<CheckoutScreen> {
  final _notesCtrl = TextEditingController();
  double? _customRate;
  bool _showCustomRate = false;

  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  double _computeTotal(double subtotal, String method, double rate) {
    if (method == 'credit') return subtotal + subtotal * rate;
    return subtotal;
  }

  Future<void> _placeOrder() async {
    final farmer   = ref.read(selectedFarmerProvider);
    final cart     = ref.read(cartProvider);
    final checkout = ref.read(checkoutProvider.notifier);

    if (farmer == null) return;

    final success = await checkout.submit(
      farmerId: farmer.id,
      cartItems: cart,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ref.read(cartProvider.notifier).clear();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 12),
            const Text('Commande enregistrée!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/home');
              },
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart     = ref.watch(cartProvider);
    final farmer   = ref.watch(selectedFarmerProvider);
    final checkout = ref.watch(checkoutProvider);
    final fmt      = NumberFormat.decimalPattern('fr');
    final subtotal = cart.fold(0.0, (s, i) => s + i.subtotal);
    final rate     = _customRate ?? 0.30;
    final total    = _computeTotal(subtotal, checkout.paymentMethod, rate);

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Farmer info
          if (farmer != null)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.person, color: AppTheme.primary),
                title: Text(farmer.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(farmer.identifier),
              ),
            ),
          const SizedBox(height: 16),

          // Payment method
          Text('Mode de paiement',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _MethodCard(
              label: 'Comptant',
              icon: Icons.payments_rounded,
              selected: checkout.paymentMethod == 'cash',
              onTap: () => ref.read(checkoutProvider.notifier).setPaymentMethod('cash'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _MethodCard(
              label: 'Crédit',
              icon: Icons.credit_card_rounded,
              selected: checkout.paymentMethod == 'credit',
              color: const Color(0xFF1565C0),
              onTap: () => ref.read(checkoutProvider.notifier).setPaymentMethod('credit'),
            )),
          ]),

          // Interest rate (credit only)
          if (checkout.paymentMethod == 'credit') ...[
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Taux d\'intérêt',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => setState(() => _showCustomRate = !_showCustomRate),
                child: Text(_showCustomRate ? 'Défaut (30%)' : 'Personnaliser'),
              ),
            ]),
            if (_showCustomRate)
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    hintText: 'Ex: 0.25 pour 25%',
                    prefixText: 'Taux: '),
                onChanged: (v) => setState(() {
                  _customRate = double.tryParse(v);
                  ref.read(checkoutProvider.notifier).setInterestRate(_customRate);
                }),
              )
            else
              Text('Taux par défaut: 30%',
                  style: TextStyle(color: Colors.grey.shade600)),
          ],
          const SizedBox(height: 16),

          // Order summary
          Text('Résumé de la commande',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                ...cart.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${item.quantity}× ${item.product.name}',
                          overflow: TextOverflow.ellipsis)),
                      Text('${fmt.format(item.subtotal.toInt())} F'),
                    ],
                  ),
                )),
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Sous-total'),
                  Text('${fmt.format(subtotal.toInt())} FCFA'),
                ]),
                if (checkout.paymentMethod == 'credit') ...[
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Intérêt (${(rate * 100).toStringAsFixed(0)}%)'),
                    Text('+${fmt.format((subtotal * rate).toInt())} FCFA',
                        style: const TextStyle(color: Colors.orange)),
                  ]),
                ],
                const Divider(),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('TOTAL',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${fmt.format(total.toInt())} FCFA',
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 16, color: AppTheme.primary)),
                ]),
              ]),
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

          if (checkout.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(checkout.error!,
                    style: const TextStyle(color: Colors.red))),
              ]),
            ),
          ],
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: checkout.isProcessing ? null : _placeOrder,
              child: checkout.isProcessing
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Confirmer — ${fmt.format(total.toInt())} FCFA'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _MethodCard({
    required this.label,
    required this.icon,
    required this.selected,
    this.color = AppTheme.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, color: selected ? Colors.white : color, size: 28),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
