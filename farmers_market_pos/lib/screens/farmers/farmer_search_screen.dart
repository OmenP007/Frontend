import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/farmer_provider.dart';
import '../../config/app_theme.dart';

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
        if (!state.isLoading && state.farmers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Text(
                '${state.farmers.length} agriculteur${state.farmers.length > 1 ? 's' : ''}',
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ]),
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
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Aucun agriculteur trouvé',
              style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Essayez un autre terme de recherche',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/farmers/new'),
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Créer un agriculteur'),
          ),
        ]),
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

        return Container(
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
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                ref.read(selectedFarmerProvider.notifier).state = f;
                context.push('/farmers/${f.id}');
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: avatarColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: avatarColor.withOpacity(0.3), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                            color: avatarColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        f.fullName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${f.identifier}${f.village != null ? ' • ${f.village}' : ''}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                    ]),
                  ),

                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chevron_right_rounded,
                        size: 18, color: Colors.grey),
                  ),
                ]),
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
