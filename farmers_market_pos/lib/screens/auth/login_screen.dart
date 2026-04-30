import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  late final AnimationController _entryCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;
  late final Animation<double>   _floatAnim;
  late final Animation<double>   _pulseAnim;
  late final Animation<double>   _cardScaleAnim;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.4), end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entryCtrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)));
    _cardScaleAnim = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack)));
    _floatAnim = Tween<double>(begin: -12.0, end: 12.0)
        .animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Hero image background ──────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // ── Dark gradient overlay ─────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xEF081C15),
                  Color(0xE81B4332),
                  Color(0xCC2D6A4F),
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
          ),

          // ── Animated floating orbs ────────────────────────────────────
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, __) => Stack(children: [
              Positioned(
                top: -size.height * 0.08 + _floatAnim.value,
                right: -size.width * 0.2,
                child: _GlowOrb(size: size.width * 0.75,
                    color: AppTheme.primary.withOpacity(0.35)),
              ),
              Positioned(
                bottom: -size.height * 0.05 - _floatAnim.value * 0.5,
                left: -size.width * 0.15,
                child: _GlowOrb(size: size.width * 0.6,
                    color: AppTheme.primaryLight.withOpacity(0.12)),
              ),
              Positioned(
                top: size.height * 0.35 + _floatAnim.value * 0.7,
                left: -size.width * 0.12,
                child: _GlowOrb(size: size.width * 0.45,
                    color: AppTheme.accent.withOpacity(0.1)),
              ),
              Positioned(
                top: size.height * 0.15 - _floatAnim.value * 0.3,
                right: size.width * 0.05,
                child: _GlowOrb(size: size.width * 0.25,
                    color: AppTheme.accentLight.withOpacity(0.08)),
              ),
            ]),
          ),

          // ── Floating particles ─────────────────────────────────────────
          ..._buildFloatingIcons(size),

          // ── Grid pattern overlay ───────────────────────────────────────
          Opacity(
            opacity: 0.03,
            child: CustomPaint(
              size: size,
              painter: _GridPainter(),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Logo area ────────────────────────────────────────
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          children: [
                            // Pulsing logo
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, child) => Transform.scale(
                                scale: _pulseAnim.value,
                                child: child,
                              ),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [AppTheme.primaryLight, AppTheme.primary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.6),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                    BoxShadow(
                                      color: AppTheme.primaryLight.withOpacity(0.2),
                                      blurRadius: 60,
                                      spreadRadius: 15,
                                    ),
                                  ],
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.25), width: 2),
                                ),
                                child: const Icon(
                                  Icons.agriculture_rounded,
                                  size: 52,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Farmers Market',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppTheme.accent.withOpacity(0.35)),
                              ),
                              child: Text(
                                'PLATEFORME AGRICOLE',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.accentLight,
                                  letterSpacing: 2.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Login Card ───────────────────────────────────────
                    ScaleTransition(
                      scale: _cardScaleAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 50,
                                offset: const Offset(0, 20),
                              ),
                              BoxShadow(
                                color: AppTheme.primaryLight.withOpacity(0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Card header
                                  Row(children: [
                                    Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppTheme.primary, AppTheme.accentLight],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 10,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Connexion',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryDark,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Accédez à votre espace de gestion',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Email field
                                  _AnimatedField(
                                    child: TextFormField(
                                      controller: _emailCtrl,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      decoration: InputDecoration(
                                        labelText: 'Adresse email',
                                        prefixIcon: Container(
                                          margin: const EdgeInsets.all(8),
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.email_outlined,
                                              size: 16, color: AppTheme.primary),
                                        ),
                                      ),
                                      validator: (v) =>
                                          (v == null || !v.contains('@')) ? 'Email invalide' : null,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Password field
                                  _AnimatedField(
                                    child: TextFormField(
                                      controller: _passwordCtrl,
                                      obscureText: _obscure,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(),
                                      decoration: InputDecoration(
                                        labelText: 'Mot de passe',
                                        prefixIcon: Container(
                                          margin: const EdgeInsets.all(8),
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.lock_outline,
                                              size: 16, color: AppTheme.primary),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            size: 20,
                                            color: Colors.grey.shade400,
                                          ),
                                          onPressed: () =>
                                              setState(() => _obscure = !_obscure),
                                        ),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.length < 6) ? 'Mot de passe trop court' : null,
                                    ),
                                  ),

                                  // Error banner
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                    child: auth.error != null
                                        ? Padding(
                                            padding: const EdgeInsets.only(top: 14),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppTheme.danger.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                    color: AppTheme.danger.withOpacity(0.3)),
                                              ),
                                              child: Row(children: [
                                                const Icon(Icons.error_outline,
                                                    color: AppTheme.danger, size: 18),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    auth.error!,
                                                    style: const TextStyle(
                                                        color: AppTheme.danger, fontSize: 13),
                                                  ),
                                                ),
                                              ]),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),

                                  const SizedBox(height: 24),

                                  // Submit button
                                  _GradientButton(
                                    onPressed: auth.isLoading ? null : _submit,
                                    isLoading: auth.isLoading,
                                    label: 'Se connecter',
                                  ),

                                  const SizedBox(height: 16),

                                  // Divider with stats
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: Colors.grey.shade200)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text('Accès sécurisé',
                                            style: Theme.of(context).textTheme.labelSmall
                                                ?.copyWith(color: Colors.grey.shade400)),
                                      ),
                                      Expanded(child: Divider(color: Colors.grey.shade200)),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Security badges
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _SecurityBadge(icon: Icons.shield_outlined, label: 'SSL'),
                                      const SizedBox(width: 16),
                                      _SecurityBadge(icon: Icons.lock_rounded, label: 'Chiffré'),
                                      const SizedBox(width: 16),
                                      _SecurityBadge(icon: Icons.verified_outlined, label: 'Vérifié'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    FadeTransition(
                      opacity: _fadeAnim,
                      child: Text(
                        '© 2025 Farmers Market Platform',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingIcons(Size size) {
    const icons = [
      Icons.grass_rounded,
      Icons.local_florist_rounded,
      Icons.eco_rounded,
      Icons.spa_rounded,
      Icons.park_rounded,
      Icons.forest_rounded,
    ];
    final rng = math.Random(7);
    return List.generate(8, (i) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final iconData = icons[i % icons.length];
      return Positioned(
        left: x,
        top: y,
        child: AnimatedBuilder(
          animation: _floatCtrl,
          builder: (_, __) {
            final offset = math.sin((_floatCtrl.value + i * 0.15) * math.pi * 2) * 10;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Opacity(
                opacity: 0.06,
                child: Icon(iconData, size: 28, color: Colors.white),
              ),
            );
          },
        ),
      );
    });
  }
}

// ── Animated field wrapper ─────────────────────────────────────────────────
class _AnimatedField extends StatefulWidget {
  final Widget child;
  const _AnimatedField({required this.child});

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 1.02)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        if (focused) {
          _ctrl.forward();
        } else {
          _ctrl.reverse();
        }
      },
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ── Decorative glow orb ────────────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: size * 0.3),
        ],
      ),
    );
  }
}

// ── Grid painter ───────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Security badge ─────────────────────────────────────────────────────────
class _SecurityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SecurityBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.primary),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.primary.withOpacity(0.7), fontSize: 10)),
      ],
    );
  }
}

// ── Gradient button ────────────────────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _GradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => _ctrl.forward() : null,
        onTapUp: isEnabled ? (_) { _ctrl.reverse(); widget.onPressed!(); } : null,
        onTapCancel: isEnabled ? () => _ctrl.reverse() : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            gradient: isEnabled
                ? const LinearGradient(
                    colors: [AppTheme.primaryLight, AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isEnabled ? null : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppTheme.primaryLight.withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (isEnabled) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
