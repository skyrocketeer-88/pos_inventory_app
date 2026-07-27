import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/finance_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/themed_app_bar.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final report = FinanceService(storage).buildReport();
    final currency = NumberFormat.currency(symbol: '\$');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const ThemedAppBar(title: 'Reports'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(label: 'Revenue', value: currency.format(report.totalRevenue), color: scheme.primary),
              _StatCard(label: 'Gross profit', value: currency.format(report.grossProfit), color: Colors.green),
              _StatCard(label: 'COGS', value: currency.format(report.totalCostOfGoodsSold), color: Colors.orange),
              _StatCard(label: 'Purchases', value: currency.format(report.totalPurchasesCost), color: Colors.blueGrey),
              _StatCard(label: 'Inventory value', value: currency.format(report.inventoryValue), color: Colors.purple),
            ],
          ),
          const SizedBox(height: 24),
          Text('Sales — last 7 days', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
                child: report.salesLast7Days.every((p) => p.total == 0)
                    ? const Center(child: Text('No sales recorded this week yet.'))
                    : BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final i = value.toInt();
                                  if (i < 0 || i >= report.salesLast7Days.length) return const SizedBox();
                                  final day = report.salesLast7Days[i].day;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(DateFormat.E().format(day), style: const TextStyle(fontSize: 11)),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (int i = 0; i < report.salesLast7Days.length; i++)
                              BarChartGroupData(x: i, barRods: [
                                BarChartRodData(
                                  toY: report.salesLast7Days[i].total,
                                  color: scheme.primary,
                                  width: 18,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ]),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Top sellers', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (report.topSellingByRevenue.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No sales yet.')))
          else
            Card(
              child: Column(
                children: report.topSellingByRevenue
                    .map((e) => ListTile(
                          title: Text(e.key.name),
                          trailing: Text(currency.format(e.value), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 24),
          Text('Revenue breakdown (top sellers)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          report.topSellingByRevenue.isEmpty
              ? const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No data for pie chart.')))
              : SizedBox(
                  height: 220,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 30,
                          sections: List.generate(
                            report.topSellingByRevenue.length > 5 ? 5 : report.topSellingByRevenue.length,
                            (i) {
                              final entry = report.topSellingByRevenue[i];
                              final value = entry.value;
                              final total = report.topSellingByRevenue.take(5).fold<double>(0, (p, e) => p + e.value);
                              final percent = total == 0 ? 0 : (value / total) * 100;
                              final colors = [scheme.primary, const Color(0xFFCBA052), Colors.green, Colors.orange, Colors.purple];
                              return PieChartSectionData(
                                value: value,
                                title: '${percent.toStringAsFixed(0)}%',
                                color: colors[i % colors.length],
                                radius: 60,
                                titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 24),
          Text('Low stock', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (report.lowStockProducts.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Everything is well stocked. 🎉')))
          else
            Card(
              child: Column(
                children: report.lowStockProducts
                    .map((p) => ListTile(
                          leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          title: Text(p.name),
                          trailing: Text('${p.quantity} left'),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(height: 10),
              Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
