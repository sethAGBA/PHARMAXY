import 'package:flutter/material.dart';

class RecentItem {
  const RecentItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.statusColor,
    this.icon = Icons.bolt,
  });

  final String title;
  final String subtitle;
  final String time;
  final Color statusColor;
  final IconData icon;
}

class RecentActivity extends StatelessWidget {
  const RecentActivity({
    super.key,
    required this.items,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
  });

  final List<RecentItem> items;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
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
            'Activités Récentes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: items.map((item) => _buildItem(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(RecentItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  item.statusColor.withOpacity(0.2),
                  item.statusColor.withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                Text(
                  item.subtitle,
                  style: TextStyle(color: subTextColor, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            item.time,
            style: TextStyle(
              color: subTextColor.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
