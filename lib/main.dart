import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app_theme.dart';
import 'models/app_user.dart';
import 'screens/dashboard_home.dart';
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
  void _toggleTheme(bool isDark) {
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
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
          home: PharmacyDashboard(
            onThemeToggle: _toggleTheme,
            isDarkMode: mode == ThemeMode.dark,
          ),
        );
      },
    );
  }
}

class PharmacyDashboard extends StatefulWidget {
  const PharmacyDashboard({super.key, required this.onThemeToggle, required this.isDarkMode});

  final ValueChanged<bool> onThemeToggle;
  final bool isDarkMode;

  @override
  State<PharmacyDashboard> createState() => _PharmacyDashboardState();
}

class _PharmacyDashboardState extends State<PharmacyDashboard> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late final List<Widget> _pages;
  late final List<NavItem> _navItems;

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
  }

  void _initNav() {
    _navItems = const [
      NavItem(icon: Icons.auto_graph_outlined, label: 'Tableau de bord'),
      NavItem(icon: Icons.point_of_sale, label: 'Vente / Caisse'),
      NavItem(icon: Icons.medical_services_outlined, label: 'Ordonnances'),
      NavItem(icon: Icons.inventory_2, label: 'Stocks'),
      NavItem(icon: Icons.report_problem_outlined, label: 'Alertes stock'),
      NavItem(icon: Icons.history, label: 'Mouvements stocks'),
      NavItem(icon: Icons.local_shipping, label: 'Commandes fournisseurs'),
      NavItem(icon: Icons.move_to_inbox_outlined, label: 'Réception livraisons'),
      NavItem(icon: Icons.diversity_3_outlined, label: 'Clients / Patients'),
      NavItem(icon: Icons.receipt_long, label: 'Facturation & compta'),
      NavItem(icon: Icons.insights_outlined, label: 'Reporting'),
      NavItem(icon: Icons.verified_user, label: 'Tiers payant'),
      NavItem(icon: Icons.biotech_outlined, label: 'Préparations'),
      NavItem(icon: Icons.fact_check, label: 'Inventaire'),
      NavItem(icon: Icons.tune, label: 'Paramétrage'),
      NavItem(icon: Icons.assignment_return, label: 'Retours'),
      NavItem(icon: Icons.health_and_safety_outlined, label: 'Conseil pharma'),
      NavItem(icon: Icons.gpp_maybe, label: 'Stupéfiants'),
      NavItem(icon: Icons.shopping_bag, label: 'E-commerce'),
    ];

    _pages = [
      const DashboardHome(),
      const VenteCaisseScreen(),
      const OrdonnancesScreen(),
      const StocksScreen(),
      const AlertesStockScreen(),
      const MouvementsStocksScreen(),
      const CommandesFournisseursScreen(),
      const ReceptionLivraisonsScreen(),
      const ClientsPatientsScreen(),
      const FacturationComptaScreen(),
      const ReportingStatsScreen(),
      const TiersPayantScreen(),
      const PreparationsMagistralesScreen(),
      const InventaireScreen(),
      const ParametrageScreen(),
      const RetoursScreen(),
      const ConseilPharmaScreen(),
      const StupefiantsScreen(),
      const EcommerceScreen(),
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
}
