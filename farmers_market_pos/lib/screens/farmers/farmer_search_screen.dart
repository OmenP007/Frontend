import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/farmer_provider.dart';
import '../../config/app_theme.dart';
import '../../widgets/animated_widgets.dart';

class FarmerSearchScreen extends ConsumerStatefulWidget {
  const FarmerSearchScreen({super.key});

  @override
  ConsumerState<FarmerSearchScreen> createState() => _State();
}

class _State extends ConsumerState<FarmerSearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(farmerSearchProvider.notifier).loadAll());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(farmerSearchProvider);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Agriculteurs',
            style: TextStyle(fontWeight: FontWeight.w800)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Nouvel agriculteur',
            onPressed: () => context.push('/farmers/new'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: TextField(
            controller: _ctrl,
            onChanged: (v) {
              setState(() {});
              ref.read(farmerSearchProvider.notifier).search(v);
            },
            decoration: InputDecoration(
              hintText: 'Nom, identifiant ou téléphone...',
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() {});
                        ref.read(farmerSearchProvider.notifier).loadAll();
                      })
                  : null,
            ),
          ),
        ),
        const Divider(height: 1),

        // Count indicator
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: !state.isLoading && state.farmers.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.people_rounded, size: 12, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${state.farmers.length} agriculteur${state.farmers.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                              color: AppTheme.primary, fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                      ]),
                    ),
                  ]),
                )
              : const SizedBox.shrink(),
        ),

        Expanded(child: _buildList(context, state)),
      ]),
    );
  }

  Widget _buildList(BuildContext context, FarmerSearchState state) {
    if (state.isLoading) return _ShimmerList();
    if (state.error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(state.error!, style: const TextStyle(color: Colors.grey)),
        ]),
      );
    }
    if (state.farmers.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'Aucun agriculteur trouvé',
        subtitle: 'Essayez un autre terme de recherche',
        action: ElevatedButton.icon(
          onPressed: () => context.push('/farmers/new'),
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: const Text('Créer un agriculteur'),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: state.farmers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final f = state.farmers[i];
        final initial = f.firstname.isNotEmpty ? f.firstname[0].toUpperCase() : '?';
        final avatarColor = AppTheme.avatarColor(initial);

        return TweenAnimationBuilder<double>(
          key: ValueKey(f.id),
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 200 + i * 50),
          curve: Curves.easeOutCubic,
          builder: (_, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - v)),
              child: child,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  ref.read(selectedFarmerProvider.notifier).state = f;
                  context.push('/farmers/${f.id}');
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    // Gradient avatar
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [avatarColor, avatarColor.withOpacity(0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: avatarColor.withOpacity(0.35),
                            blurRadius: 12, offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(initial,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f.fullName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 3),
                        Text(
                          '${f.identifier}${f.village != null ? ' • ${f.village}' : ''}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F8F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppTheme.primary),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Shimmer List ───────────────────────────────────────────────────────────
class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
