import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/farmer_provider.dart';
import '../../config/app_theme.dart';

class FarmerDetailScreen extends ConsumerStatefulWidget {
  final int farmerId;
  const FarmerDetailScreen({super.key, required this.farmerId});

  @override
  ConsumerState<FarmerDetailScreen> createState() => _State();
}

class _State extends ConsumerState<FarmerDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(farmerDetailProvider.notifier).load(widget.farmerId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(farmerDetailProvider);
    final fmt   = NumberFormat.decimalPattern('fr');

    if (state.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 16),
            Text('Chargement...', style: TextStyle(color: Colors.grey.shade500)),
          ]),
        ),
      );
    }
    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agriculteur')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: Colors.grey)),
          ]),
        ),
      );
    }

    final farmer = state.farmer!;
    final initial = farmer.firstname.isNotEmpty ? farmer.firstname[0].toUpperCase() : '?';
    final avatarColor = AppTheme.avatarColor(initial);
    final debtRatio = farmer.creditLimitFcfa > 0
        ? (state.totalDebt / farmer.creditLimitFcfa).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Sliver Header ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: avatarColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      avatarColor,
                      avatarColor.withOpacity(0.7),
                      AppTheme.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                    child: Row(children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white38, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                                fontSize: 30,
                                color: Colors.white,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            farmer.fullName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            farmer.identifier,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          if (farmer.village != null) ...[
                            const SizedBox(height: 2),
                            Row(children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Colors.white60, size: 13),
                              const SizedBox(width: 4),
                              Text(farmer.village!,
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 12)),
                            ]),
                          ],
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Infos rapides ─────────────────────────────────────────
                if (farmer.phone != null)
                  _InfoChip(icon: Icons.phone_rounded, label: farmer.phone!),
                if (farmer.phone != null) const SizedBox(height: 16),

                // ── Credit Overview ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Limite de crédit',
                          value: '${fmt.format(farmer.creditLimitFcfa)} FCFA',
                          icon: Icons.credit_score_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      Container(
                          width: 1, height: 50, color: const Color(0xFFEEEEEE)),
                      Expanded(
                        child: _MiniStat(
                          label: 'Dette totale',
                          value: '${fmt.format(state.totalDebt.toInt())} FCFA',
                          icon: Icons.money_off_rounded,
                          color: state.totalDebt > 0
                              ? AppTheme.danger
                              : Colors.grey,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Available credit bar
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Crédit disponible',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        '${fmt.format(state.availableCredit.toInt())} FCFA',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: state.availableCredit > 0
                                ? AppTheme.primary
                                : AppTheme.danger,
                            fontSize: 15),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: debtRatio,
                        minHeight: 10,
                        backgroundColor: AppTheme.primary.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          debtRatio < 0.5
                              ? AppTheme.success
                              : debtRatio < 0.8
                                  ? AppTheme.warning
                                  : AppTheme.danger,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('0 FCFA',
                          style: TextStyle(color: Colors.grey, fontSize: 10)),
                      Text('${(debtRatio * 100).toStringAsFixed(0)}% utilisé',
                          style: TextStyle(
                              color: debtRatio < 0.8
                                  ? Colors.grey
                                  : AppTheme.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                      Text('${fmt.format(farmer.creditLimitFcfa)} FCFA',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 10)),
                    ]),
                  ]),
                ),

                const SizedBox(height: 16),

                // ── Action buttons ────────────────────────────────────────
                Row(children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_shopping_cart_rounded,
                      label: 'Nouvelle commande',
                      color: AppTheme.primary,
                      onTap: () {
                        ref.read(selectedFarmerProvider.notifier).state =
                            state.farmer;
                        context.push('/products');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.payments_rounded,
                      label: 'Remboursement',
                      color: const Color(0xFFE65100),
                      onTap: () {
                        ref.read(selectedFarmerProvider.notifier).state =
                            state.farmer;
                        context.push('/repayment');
                      },
                    ),
                  ),
                ]),

                const SizedBox(height: 24),

                // ── Debts section ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Dettes en cours',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: state.debts.isEmpty
                            ? AppTheme.success.withOpacity(0.1)
                            : AppTheme.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.debts.length}',
                        style: TextStyle(
                            color: state.debts.isEmpty
                                ? AppTheme.success
                                : AppTheme.danger,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (state.debts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.success.withOpacity(0.2)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppTheme.success, size: 24),
                      SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Aucune dette en cours',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('Cet agriculteur est à jour',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12)),
                      ]),
                    ]),
                  )
                else
                  ...state.debts.asMap().entries.map((entry) {
                    final d = entry.value;
                    final paid = d.percentPaid.clamp(0.0, 1.0);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt_long_rounded,
                                    color: AppTheme.danger, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Text('Transaction #${d.transactionId}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ]),
                            Text(
                              DateFormat('dd/MM/yyyy').format(d.createdAt),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: paid,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              paid < 0.5
                                  ? AppTheme.danger
                                  : paid < 0.8
                                      ? AppTheme.warning
                                      : AppTheme.success,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Restant: ${fmt.format(d.remainingAmountFcfa.toInt())} FCFA',
                              style: TextStyle(
                                  color: AppTheme.danger,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                            Text(
                              '${(paid * 100).toStringAsFixed(0)}% payé',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ]),
                    );
                  }),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Chip ──────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AppTheme.primary, size: 16),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ]),
    );
  }
}

// ── Mini Stat ──────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.w800,
                color: color,
                fontSize: 14)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
    );
  }
}

// ── Action Button ──────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ]),
      ),
    );
  }
}
