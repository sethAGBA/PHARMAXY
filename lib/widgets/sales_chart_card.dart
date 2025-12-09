import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SalesChartCard extends StatelessWidget {
  const SalesChartCard({
    super.key,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.dividerColor,
    this.height = 360,
  });

  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color dividerColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Évolution des Ventes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: height,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toInt()}K',
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin'];
                        return Text(
                          months[value.toInt() % months.length],
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: dividerColor)),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 450000),
                      FlSpot(1, 520000),
                      FlSpot(2, 580000),
                      FlSpot(3, 620000),
                      FlSpot(4, 710000),
                      FlSpot(5, 800000),
                    ],
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 4,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF10B981).withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
