import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class FarmerFormScreen extends ConsumerStatefulWidget {
  const FarmerFormScreen({super.key});
  @override
  ConsumerState<FarmerFormScreen> createState() => _State();
}

class _State extends ConsumerState<FarmerFormScreen> {
  final _form        = GlobalKey<FormState>();
  final _firstCtrl   = TextEditingController();
  final _lastCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _limitCtrl   = TextEditingController(text: '500000');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose();
    _phoneCtrl.dispose(); _villageCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(apiServiceProvider);
      await api.createFarmer({
        'firstname':         _firstCtrl.text.trim(),
        'lastname':          _lastCtrl.text.trim(),
        'phone':             _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'village':           _villageCtrl.text.trim().isEmpty ? null : _villageCtrl.text.trim(),
        'credit_limit_fcfa': int.tryParse(_limitCtrl.text) ?? 500000,
      });
      if (mounted) context.pop();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel Agriculteur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _field(_firstCtrl, 'Prénom', required: true,
                icon: Icons.person_outline),
            const SizedBox(height: 14),
            _field(_lastCtrl, 'Nom de famille', required: true,
                icon: Icons.person_outline),
            const SizedBox(height: 14),
            _field(_phoneCtrl, 'Téléphone', icon: Icons.phone_outlined,
                type: TextInputType.phone),
            const SizedBox(height: 14),
            _field(_villageCtrl, 'Village / Localité', icon: Icons.location_on_outlined),
            const SizedBox(height: 14),
            _field(_limitCtrl, 'Limite de crédit (FCFA)', required: true,
                icon: Icons.credit_score, type: TextInputType.number),
            const SizedBox(height: 10),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Créer l\'agriculteur'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, IconData? icon, TextInputType? type}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null
          : null,
    );
  }
}
