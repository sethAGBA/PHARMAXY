import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app_theme.dart';
import 'models/app_user.dart';
import 'screens/dashboard_home.dart';
import 'screens/login.dart';
import 'screens/vente_caisse.dart';
import 'screens/ordonnances.dart';
import 'screens/stocks.dart';
import 'screens/mouvements_stocks.dart';
import 'screens/alertes_stock.dart';
import 'screens/commandes_fournisseurs.dart';
import 'screens/reception_livraisons.dart';
import 'screens/clients_patients.dart';
import 'screens/facturation_compta.dart';
import 'screens/reporting_stats.dart';
import 'screens/tiers_payant.dart';
import 'screens/preparations_magistrales.dart';
import 'screens/inventaire.dart';
import 'screens/parametrage.dart';
import 'screens/retours.dart';
import 'screens/conseil_pharma.dart';
import 'screens/stupefiants.dart';
import 'screens/ecommerce.dart';
import 'services/auth_service.dart';
import 'services/local_database_service.dart';
import 'widgets/sidebar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await _initializeLocalData();
  runApp(const MyApp());
}

// Global navigator key to allow dialogs from services/widgets.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _initializeLocalData() async {
  // Minimal bootstrap inspired by afroforma: init local DB and create a default admin.
  await LocalDatabaseService.instance.init();
  final existing = await LocalDatabaseService.instance.getUsers();
    if (existing.isEmpty) {
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
    }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppUser? _currentUser;
  bool _isBootstrapping = true;

  @override
  void initState() {
    super.initState();
    _bootstrapSession();
  }

  Future<void> _bootstrapSession() async {
    // Always ask for a password on startup: no auto-login, only remember the identifier.
    setState(() => _isBootstrapping = false);
  }

  void _toggleTheme(bool isDark) {
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void _onLogin(AppUser user) {
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _onLogout() async {
    await AuthService.instance.logout();
    if (mounted) {
      setState(() => _currentUser = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'PHARMAXY',
          navigatorKey: navigatorKey,
          themeMode: mode,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          home: _isBootstrapping
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : _currentUser == null
              ? LoginScreen(onLogin: _onLogin)
              : PharmacyDashboard(
                  onThemeToggle: _toggleTheme,
                  isDarkMode: mode == ThemeMode.dark,
                  onLogout: _onLogout,
                  currentUser: _currentUser!,
                ),
        );
      },
    );
  }
}

class PharmacyDashboard extends StatefulWidget {
  const PharmacyDashboard({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
    required this.onLogout,
    required this.currentUser,
  });

  final ValueChanged<bool> onThemeToggle;
  final bool isDarkMode;
  final VoidCallback onLogout;
  final AppUser currentUser;

  @override
  State<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends State<PharmacyDashboard>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late final List<_NavEntry> _allEntries;
  List<_NavEntry> _entries = [];
  List<Widget> _pages = [];
  List<NavItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _initNav();
    _buildNavigationForUser();
  }

  void _initNav() {
    _allEntries = [
      _NavEntry(
        id: 'dashboard',
        nav: const NavItem(
          icon: Icons.auto_graph_outlined,
          label: 'Tableau de bord',
        ),
        pageBuilder: () =>
            DashboardHome(onNavigate: _handleDashboardNavigation),
      ),
      _NavEntry(
        id: 'vente',
        nav: const NavItem(icon: Icons.point_of_sale, label: 'Vente / Caisse'),
        pageBuilder: () => const VenteCaisseScreen(),
      ),
      _NavEntry(
        id: 'ordonnances',
        nav: const NavItem(
          icon: Icons.medical_services_outlined,
          label: 'Ordonnances',
        ),
        pageBuilder: () => const OrdonnancesScreen(),
      ),
      _NavEntry(
        id: 'stocks',
        nav: const NavItem(icon: Icons.inventory_2, label: 'Stocks'),
        pageBuilder: () => const StocksScreen(),
      ),
      _NavEntry(
        id: 'alertes',
        nav: const NavItem(
          icon: Icons.report_problem_outlined,
          label: 'Alertes stock',
        ),
        pageBuilder: () => const AlertesStockScreen(),
      ),
      _NavEntry(
        id: 'mouvements',
        nav: const NavItem(icon: Icons.history, label: 'Mouvements stocks'),
        pageBuilder: () => const MouvementsStocksScreen(),
      ),
      _NavEntry(
        id: 'commandes',
        nav: const NavItem(
          icon: Icons.local_shipping,
          label: 'Commandes fournisseurs',
        ),
        pageBuilder: () => const CommandesFournisseursScreen(),
      ),
      _NavEntry(
        id: 'receptions',
        nav: const NavItem(
          icon: Icons.move_to_inbox_outlined,
          label: 'Réception livraisons',
        ),
        pageBuilder: () => const ReceptionLivraisonsScreen(),
      ),
      _NavEntry(
        id: 'clients',
        nav: const NavItem(
          icon: Icons.diversity_3_outlined,
          label: 'Clients / Patients',
        ),
        pageBuilder: () => const ClientsPatientsScreen(),
      ),
      _NavEntry(
        id: 'facturation',
        nav: const NavItem(
          icon: Icons.receipt_long,
          label: 'Facturation & compta',
        ),
        pageBuilder: () => const FacturationComptaScreen(),
      ),
      _NavEntry(
        id: 'reporting',
        nav: const NavItem(icon: Icons.insights_outlined, label: 'Reporting'),
        pageBuilder: () => const ReportingStatsScreen(),
      ),
      _NavEntry(
        id: 'tiers',
        nav: const NavItem(icon: Icons.verified_user, label: 'Tiers payant'),
        pageBuilder: () => const TiersPayantScreen(),
      ),
      _NavEntry(
        id: 'preparations',
        nav: const NavItem(icon: Icons.biotech_outlined, label: 'Préparations'),
        pageBuilder: () => const PreparationsMagistralesScreen(),
      ),
      _NavEntry(
        id: 'inventaire',
        nav: const NavItem(icon: Icons.fact_check, label: 'Inventaire'),
        pageBuilder: () => const InventaireScreen(),
      ),
      _NavEntry(
        id: 'parametrage',
        nav: const NavItem(icon: Icons.tune, label: 'Paramétrage'),
        pageBuilder: () => const ParametrageScreen(),
      ),
      _NavEntry(
        id: 'retours',
        nav: const NavItem(icon: Icons.assignment_return, label: 'Retours'),
        pageBuilder: () => const RetoursScreen(),
      ),
      _NavEntry(
        id: 'conseil',
        nav: const NavItem(
          icon: Icons.health_and_safety_outlined,
          label: 'Conseil pharma',
        ),
        pageBuilder: () => const ConseilPharmaScreen(),
      ),
      _NavEntry(
        id: 'stupefiants',
        nav: const NavItem(icon: Icons.gpp_maybe, label: 'Stupéfiants'),
        pageBuilder: () => const StupefiantsScreen(),
      ),
      _NavEntry(
        id: 'ecommerce',
        nav: const NavItem(icon: Icons.shopping_bag, label: 'E-commerce'),
        pageBuilder: () => const EcommerceScreen(),
      ),
    ];
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
                _animationController.forward(from: 0);
              });
            },
            isDarkMode: widget.isDarkMode,
            onThemeToggle: widget.onThemeToggle,
            animationController: _animationController,
            items: _navItems,
            onLogout: _confirmLogout,
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  void _buildNavigationForUser() {
    final allowed = widget.currentUser.allowedScreens;
    final allowedSet = allowed.isEmpty ? null : allowed.toSet();
    _entries = _allEntries
        .where((entry) => allowedSet == null || allowedSet.contains(entry.id))
        .toList();
    if (_entries.isEmpty) {
      _entries = _allEntries;
    }
    _navItems = _entries.map((e) => e.nav).toList();
    _pages = _entries.map((e) => e.pageBuilder()).toList();
    _selectedIndex = _selectedIndex.clamp(0, _entries.length - 1);
    setState(() {});
  }

  void _handleDashboardNavigation(String targetId) {
    final index = _entries.indexWhere((entry) => entry.id == targetId);
    if (index == -1) return;
    setState(() {
      _selectedIndex = index;
      _animationController.forward(from: 0);
    });
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      widget.onLogout();
    }
  }
}

class _NavEntry {
  const _NavEntry({
    required this.id,
    required this.nav,
    required this.pageBuilder,
  });

  final String id;
  final NavItem nav;
  final Widget Function() pageBuilder;
}
