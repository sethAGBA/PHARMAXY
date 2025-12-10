import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../app_theme.dart';
import '../models/app_user.dart';
import '../screens/double_authentication_screen.dart';
import '../services/auth_service.dart';
import '../services/local_database_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final ValueChanged<AppUser> onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscure = true;
  String? _error;

  late AnimationController _animationController;
  late AnimationController _floatingController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    // Animation principale
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Animation de flottement
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Animation de secousse pour les erreurs
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animationController.forward();
    _prefillRemembered();
  }

  Future<void> _prefillRemembered() async {
    final remembered = await AuthService.instance.getRememberedIdentifier();
    if (!mounted) return;
    setState(() {
      if (remembered != null) {
        _identifierController.text = remembered;
        _rememberMe = true;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    _shakeController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      _shakeController.forward(from: 0);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = await AuthService.instance.login(
      _identifierController.text.trim(),
      _passwordController.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;

    if (user == null) {
      _shakeController.forward(from: 0);
      setState(() {
        _isLoading = false;
        _error = 'Identifiants invalides ou compte inactif';
      });
      return;
    }

    setState(() {
      _isLoading = false;
    });
    final passed = await _requireDoubleAuth(user);
    if (!mounted) return;
    if (!passed) {
      setState(() {
        _error = 'Double authentification requise';
      });
      return;
    }
    widget.onLogin(user);
  }

  Future<bool> _requireDoubleAuth(AppUser user) async {
    if (!user.twoFactorEnabled) return true;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DoubleAuthenticationScreen(user: user),
      ),
    );
    return result == true;
  }

  Future<void> _restoreAdmin() async {
    // Afficher la boîte de dialogue de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Confirmer la restauration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir restaurer le compte administrateur par défaut ?',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Identifiants :',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '📧 Email: admin@pharmaxy.local',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '🔑 Mot de passe: admin123',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Restaurer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );

    // Si l'utilisateur n'a pas confirmé, on arrête
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await LocalDatabaseService.instance.insertUser(
        AppUser(
          id: 'admin',
          name: 'Admin',
          email: 'admin@pharmaxy.local',
          password: 'admin123',
          role: 'admin',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          isActive: true,
          twoFactorEnabled: false,
          totpSecret: null,
          allowedScreens: const [],
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Compte admin restauré avec succès !')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    final gradientColors = palette.isDark
        ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0D9488)]
        : const [Color(0xFF06B6D4), Color(0xFF3B82F6), Color(0xFF8B5CF6)];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          children: [
            // Bulles décoratives animées
            ...List.generate(5, (index) {
              return AnimatedBuilder(
                animation: _floatingController,
                builder: (context, child) {
                  return Positioned(
                    top:
                        50.0 +
                        (index * 150.0) +
                        _floatingAnimation.value * (index % 2 == 0 ? 1 : -1),
                    left: 20.0 + (index * 80.0),
                    child: _buildFloatingCircle(
                      60.0 + (index * 20.0),
                      palette,
                      opacity: 0.05 + (index * 0.02),
                    ),
                  );
                },
              );
            }),

            // Effet de glassmorphism
            Positioned.fill(
              child: CustomPaint(
                painter: _GlassMorphismPainter(animation: _floatingController),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: _buildLoginCard(palette, gradientColors),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(ThemeColors palette, List<Color> gradientColors) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset = math.sin(_shakeController.value * math.pi * 4) * 8;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: Card(
        elevation: 24,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.card, palette.card.withOpacity(0.95)],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(palette.isDark ? 0.1 : 0.2),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Effet de brillance
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          gradientColors.last.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(palette, gradientColors),
                        const SizedBox(height: 36),
                        _buildIdentifierField(palette, gradientColors),
                        const SizedBox(height: 20),
                        _buildPasswordField(palette, gradientColors),
                        const SizedBox(height: 16),
                        _buildRememberMeRow(palette),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          _buildErrorMessage(),
                        ],
                        const SizedBox(height: 24),
                        _buildLoginButton(gradientColors),
                        const SizedBox(height: 16),
                        _buildRestoreAdminButton(palette),
                        const SizedBox(height: 16),
                        _buildDefaultCredentials(palette),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors palette, List<Color> gradientColors) {
    return Column(
      children: [
        // Image avec hauteur réduite et design moderne
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: gradientColors.last.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Image de fond
                Image.asset(
                  'assets/images/pharmacy_icon.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                // Overlay gradient sophistiqué
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradientColors[1].withOpacity(0.7),
                        gradientColors.last.withOpacity(0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Effet de brillance
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        // Titre principal modernisé
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [gradientColors[1], gradientColors.last],
          ).createShader(bounds),
          child: const Text(
            'PHARMAXY',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Sous-titre élégant
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: gradientColors.last.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: gradientColors.last.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            'Système de Gestion Pharmaceutique',
            style: TextStyle(
              fontSize: 12,
              color: palette.subText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Message d'accueil moderne
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: 15, color: palette.text, height: 1.4),
            children: [
              TextSpan(
                text: 'Connectez-vous',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: gradientColors.last,
                ),
              ),
              const TextSpan(
                text: ' pour accéder à\nvotre espace de travail',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdentifierField(
    ThemeColors palette,
    List<Color> gradientColors,
  ) {
    return TextFormField(
      controller: _identifierController,
      decoration: InputDecoration(
        labelText: 'Email ou identifiant',
        hintText: 'Entrez votre email',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: gradientColors.last.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.person_outline,
            color: gradientColors.last,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: gradientColors.last, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: palette.isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey[50],
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Ce champ est requis' : null,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildPasswordField(ThemeColors palette, List<Color> gradientColors) {
    return TextFormField(
      controller: _passwordController,
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        hintText: 'Entrez votre mot de passe',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: gradientColors.last.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.lock_outline, color: gradientColors.last, size: 20),
        ),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: palette.subText,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: gradientColors.last, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: palette.isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey[50],
      ),
      obscureText: _obscure,
      validator: (v) => (v == null || v.isEmpty) ? 'Ce champ est requis' : null,
      onFieldSubmitted: (_) => _isLoading ? null : _login(),
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildRememberMeRow(ThemeColors palette) {
    return Row(
      children: [
        Transform.scale(
          scale: 1.1,
          child: Checkbox(
            value: _rememberMe,
            onChanged: (v) => setState(() => _rememberMe = v ?? false),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        Text(
          'Se souvenir de moi',
          style: TextStyle(
            color: palette.text,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _isLoading ? null : _prefillRemembered,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Pré-remplir'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(List<Color> gradientColors) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientColors[1], gradientColors.last],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Se connecter',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreAdminButton(ThemeColors palette) {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _restoreAdmin,
      icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
      label: const Text('Restaurer le compte admin'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: palette.subText.withOpacity(0.3), width: 1.5),
      ),
    );
  }

  Widget _buildDefaultCredentials(ThemeColors palette) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.subText.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: palette.subText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'admin@pharmaxy.local / admin123',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.subText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCircle(
    double size,
    ThemeColors palette, {
    double opacity = 0.1,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (palette.isDark ? Colors.white : Colors.black).withOpacity(
          opacity,
        ),
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 20),
        ],
      ),
    );
  }
}

class _GlassMorphismPainter extends CustomPainter {
  final Animation<double> animation;

  _GlassMorphismPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    final path = Path();
    final offset = animation.value * 50;

    path.moveTo(0, size.height * 0.3 + offset);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.2 + offset,
      size.width * 0.5,
      size.height * 0.3 + offset,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.4 + offset,
      size.width,
      size.height * 0.3 + offset,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
