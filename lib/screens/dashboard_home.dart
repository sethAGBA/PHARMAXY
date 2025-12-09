import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../services/product_service.dart';
import '../services/local_database_service.dart';
import '../widgets/sales_chart_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_activity.dart';
import '../widgets/stats_card.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _loadMetrics();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1100;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(palette),
              const SizedBox(height: 24),
              _buildStats(palette, isWide),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: SalesChartCard(
                                height: 360,
                                cardColor: palette.card,
                                textColor: palette.text,
                                subTextColor: palette.subText,
                                dividerColor: palette.divider,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildRightColumn(palette),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            SalesChartCard(
                              height: 360,
                              cardColor: palette.card,
                              textColor: palette.text,
                              subTextColor: palette.subText,
                              dividerColor: palette.divider,
                            ),
                            const SizedBox(height: 20),
                            _buildRightColumn(palette),
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeColors palette) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tableau de Bord Pharmacie',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: palette.text,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Gérez votre pharmacie avec style et efficacité',
              style: TextStyle(
                fontSize: 16,
                color: palette.subText,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF34D399)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.circle, color: palette.text, size: 10),
              const SizedBox(width: 8),
              Text(
                'Système Actif',
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats(ThemeColors palette, bool isWide) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: LayoutBuilder(
        builder: (context, innerConstraints) {
          final wideStats = innerConstraints.maxWidth > 1100;
          final cardWidth = wideStats ? (innerConstraints.maxWidth - 60) / 4 : (innerConstraints.maxWidth - 20) / 2;
          return Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              SizedBox(
                width: cardWidth,
                child: StatsCard(
                  title: 'Ventes Aujourd\'hui',
                  value: _todaySalesFormatted,
                  icon: Icons.attach_money,
                  color: const Color(0xFF10B981),
                  subtitle: _todayChangeLabel,
                  cardColor: palette.card,
                  textColor: palette.text,
                  subTextColor: palette.subText,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: StatsCard(
                  title: 'Médicaments',
                  value: _medsCount.toString(),
                  icon: Icons.medication,
                  color: const Color(0xFF3B82F6),
                  subtitle: 'Catégories: $_familiesCount',
                  cardColor: palette.card,
                  textColor: palette.text,
                  subTextColor: palette.subText,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: StatsCard(
                  title: 'Stock Faible',
                  value: _lowStockCount.toString(),
                  icon: Icons.warning,
                  color: const Color(0xFFF59E0B),
                  subtitle: 'Action requise',
                  cardColor: palette.card,
                  textColor: palette.text,
                  subTextColor: palette.subText,
                ),
              ),
              SizedBox(
                width: cardWidth,
                child: StatsCard(
                  title: 'Clients',
                  value: _clientsCount.toString(),
                  icon: Icons.people,
                  color: const Color(0xFF8B5CF6),
                  subtitle: '+${_newClientsThisMonth} ce mois',
                  cardColor: palette.card,
                  textColor: palette.text,
                  subTextColor: palette.subText,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Metrics state
  double _todaySales = 0.0;
  String _todaySalesFormatted = '0 FCFA';
  String _todayChangeLabel = '';
  int _medsCount = 0;
  int _familiesCount = 0;
  int _lowStockCount = 0;
  int _clientsCount = 0;
  int _newClientsThisMonth = 0;

  Future<void> _loadMetrics() async {
    try {
      // Products / stock
      final entries = await ProductService.instance.fetchStockEntries();
      _medsCount = entries.length;
      final families = <String>{};
      int lowCount = 0;
      // total stock value can be computed if needed
      for (final e in entries) {
        families.add(e.family);
        final total = e.qtyOfficine + e.qtyReserve;
        if (total <= 0 || total < e.seuil) lowCount++;
      }
      _familiesCount = families.length;
      _lowStockCount = lowCount;

      // Sales today
      final now = DateTime.now();

      // Use DB directly for accurate date filtering
      final db = LocalDatabaseService.instance.db;
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final rows = await db.rawQuery('SELECT SUM(montant) as total FROM ventes WHERE date >= ? AND date <= ?', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);
      final total = rows.isNotEmpty ? (rows.first['total'] as num?)?.toDouble() ?? 0.0 : 0.0;
      _todaySales = total;
      final fmt = NumberFormat.decimalPattern('fr_FR');
      _todaySalesFormatted = '${fmt.format(_todaySales)} FCFA';

      // Clients count
      final clientCountRow = await db.rawQuery('SELECT COUNT(*) as c FROM patients');
      _clientsCount = clientCountRow.isNotEmpty ? (clientCountRow.first['c'] as int?) ?? 0 : 0;

      // New clients this month
      final monthStart = DateTime(now.year, now.month, 1);
      final newClientsRow = await db.rawQuery('SELECT COUNT(*) as c FROM patients WHERE created_at >= ?', [monthStart.toIso8601String()]);
      _newClientsThisMonth = newClientsRow.isNotEmpty ? (newClientsRow.first['c'] as int?) ?? 0 : 0;

      setState(() {});
    } catch (e) {
      // ignore for now, keep demo values visible if needed
      setState(() {});
    }
  }

  Widget _buildRightColumn(ThemeColors palette) {
    final recentItems = [
      const RecentItem(
        title: 'Vente effectuée',
        subtitle: 'Paracétamol 500mg - 15,000 FCFA',
        time: '5min',
        statusColor: Color(0xFF10B981),
        icon: Icons.shopping_cart,
      ),
      const RecentItem(
        title: 'Stock réapprovisionné',
        subtitle: 'Amoxicilline - 500 unités',
        time: '1h',
        statusColor: Color(0xFF3B82F6),
        icon: Icons.inventory_2,
      ),
      const RecentItem(
        title: 'Alerte stock bas',
        subtitle: 'Aspirine 100mg - 12 restants',
        time: '2h',
        statusColor: Color(0xFFF59E0B),
        icon: Icons.warning_amber,
      ),
      const RecentItem(
        title: 'Produit périmé',
        subtitle: 'Sirop Toux - Expire dans 7j',
        time: '3h',
        statusColor: Color(0xFFEF4444),
        icon: Icons.error_outline,
      ),
    ];

    final actions = [
      const QuickActionItem(title: 'Nouvelle Vente', icon: Icons.add_shopping_cart, color: Color(0xFF10B981)),
      const QuickActionItem(title: 'Ajouter Produit', icon: Icons.add_box, color: Color(0xFF3B82F6)),
      const QuickActionItem(title: 'Inventaire', icon: Icons.fact_check, color: Color(0xFFF59E0B)),
      const QuickActionItem(title: 'Rapport Ventes', icon: Icons.assessment, color: Color(0xFF8B5CF6)),
    ];

    return Column(
      children: [
        RecentActivity(
          items: recentItems,
          cardColor: palette.card,
          textColor: palette.text,
          subTextColor: palette.subText,
        ),
        const SizedBox(height: 20),
        QuickActions(
          actions: actions,
          cardColor: palette.card,
          textColor: palette.text,
        ),
      ],
    );
  }
}
