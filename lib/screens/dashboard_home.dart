import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../app_theme.dart';
import '../models/sale_models.dart';
import '../services/local_database_service.dart';
import '../services/product_service.dart';
import '../services/sales_service.dart';
import '../widgets/sales_chart_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_activity.dart';
import '../widgets/stats_card.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key, required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  List<FlSpot> _salesSpots = [];
  List<String> _salesLabels = [];
  List<SaleRecord> _recentSales = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
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
                                spots: _salesSpots,
                                labels: _salesLabels,
                                title: 'Évolution des ventes (6 derniers mois)',
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(child: _buildRightColumn(palette)),
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
                              spots: _salesSpots,
                              labels: _salesLabels,
                              title: 'Évolution des ventes (6 derniers mois)',
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
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5A4), Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    'assets/images/pharmacy_icon.jpg',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
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
                  style: TextStyle(fontSize: 16, color: palette.subText),
                ),
              ],
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
          final cardWidth = wideStats
              ? (innerConstraints.maxWidth - 60) / 4
              : (innerConstraints.maxWidth - 20) / 2;
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
      final rows = await db.rawQuery(
        'SELECT SUM(montant) as total FROM ventes WHERE date >= ? AND date <= ?',
        [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      );
      final total = rows.isNotEmpty
          ? (rows.first['total'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      _todaySales = total;
      final fmt = NumberFormat.decimalPattern('fr_FR');
      _todaySalesFormatted = '${fmt.format(_todaySales)} FCFA';

      // Clients count
      final clientCountRow = await db.rawQuery(
        'SELECT COUNT(*) as c FROM patients',
      );
      _clientsCount = clientCountRow.isNotEmpty
          ? (clientCountRow.first['c'] as int?) ?? 0
          : 0;

      // New clients this month
      final monthStart = DateTime(now.year, now.month, 1);
      final newClientsRow = await db.rawQuery(
        'SELECT COUNT(*) as c FROM patients WHERE created_at >= ?',
        [monthStart.toIso8601String()],
      );
      _newClientsThisMonth = newClientsRow.isNotEmpty
          ? (newClientsRow.first['c'] as int?) ?? 0
          : 0;
      await _populateSalesTrend(db, now);
      _recentSales = await SalesService.instance.fetchSalesHistory(limit: 5);
      setState(() {});
    } catch (e) {
      // ignore for now, keep demo values visible if needed
      setState(() {});
    }
  }

  Future<void> _populateSalesTrend(Database db, DateTime now) async {
    final start = DateTime(now.year, now.month - 5, 1);
    final rows = await db.rawQuery(
      '''
SELECT strftime('%Y-%m', date) as month, SUM(montant) as total
FROM ventes
WHERE date >= ?
GROUP BY month
ORDER BY month ASC
''',
      [start.toIso8601String()],
    );
    final totals = <String, double>{};
    for (final row in rows) {
      final key = row['month'] as String?;
      if (key != null) {
        totals[key] = (row['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    final spots = <FlSpot>[];
    final labels = <String>[];
    for (int i = 0; i < 6; i++) {
      final dt = DateTime(now.year, now.month - 5 + i, 1);
      final key = DateFormat('yyyy-MM').format(dt);
      final label = DateFormat('MMM yy', 'fr_FR').format(dt);
      final value = totals[key] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), value));
      labels.add(label);
    }
    _salesSpots = spots;
    _salesLabels = labels;
  }

  Widget _buildRightColumn(ThemeColors palette) {
    final recentItems = _recentSales.isEmpty
        ? [
            RecentItem(
              title: 'Aucune activité récente',
              subtitle: 'Réalisé une vente pour déclencher le suivi',
              time: 'Maintenant',
              statusColor: const Color(0xFF10B981),
              icon: Icons.remove_circle_outline,
            ),
          ]
        : _recentSales.map((sale) {
            final amount = NumberFormat(
              '#,###',
              'fr_FR',
            ).format(sale.total.abs());
            final subtitle =
                '$amount FCFA • ${sale.paymentMethod.isNotEmpty ? sale.paymentMethod : 'Mode non défini'}';
            final statusColor = sale.status == 'Réglée'
                ? const Color(0xFF10B981)
                : Colors.orange;
            final icon = sale.total < 0
                ? Icons.keyboard_return
                : Icons.shopping_cart;
            return RecentItem(
              title: sale.id,
              subtitle: subtitle,
              time: sale.timeLabel,
              statusColor: statusColor,
              icon: icon,
            );
          }).toList();

    final actions = [
      QuickActionItem(
        title: 'Nouvelle vente',
        icon: Icons.point_of_sale,
        color: const Color(0xFF10B981),
        onPressed: () => widget.onNavigate('vente'),
      ),
      QuickActionItem(
        title: 'Ajouter produit',
        icon: Icons.add_box,
        color: const Color(0xFF3B82F6),
        onPressed: () => widget.onNavigate('stocks'),
      ),
      QuickActionItem(
        title: 'Inventaire',
        icon: Icons.fact_check,
        color: const Color(0xFFF59E0B),
        onPressed: () => widget.onNavigate('inventaire'),
      ),
      QuickActionItem(
        title: 'Commandes',
        icon: Icons.local_shipping,
        color: const Color(0xFF8B5CF6),
        onPressed: () => widget.onNavigate('commandes'),
      ),
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
