import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/production_batch.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import 'premium_card.dart';

class AnalyticsDashboard extends StatelessWidget {
  final List<ProductionBatch> batches;
  final int daysToShow;

  const AnalyticsDashboard({
    super.key,
    required this.batches,
    this.daysToShow = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (batches.isEmpty) {
      return PremiumCard(
        padding: const EdgeInsets.all(AppTheme.spacing40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 48,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            Text(
              'No Analytics Data Available',
              style: AppTheme.headlineMedium.copyWith(
                color: AppColors.neutral900,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'Create production batches to unlock powerful analytics and business insights',
              textAlign: TextAlign.center,
              style: AppTheme.bodyLarge.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.info.withOpacity(0.1),
                      AppColors.info.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.info.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing6),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pro Tip',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing2),
                          Text(
                            'Analytics appear after your first batch',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.info.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
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

    final recentBatches = _getRecentBatches();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        PremiumCardHeader(
          title: 'Business Analytics',
          subtitle: 'Performance insights and trends analysis',
          icon: Icons.insights,
          iconColor: AppColors.primaryBlue,
        ),
        const SizedBox(height: AppTheme.spacing20),
        
        // KPI Cards Row
        _buildKPICards(context),
        const SizedBox(height: AppTheme.spacing32),
        
        // Charts Row
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildProfitTrendChart(context, recentBatches),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEfficiencyDistribution(context, recentBatches),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildProfitTrendChart(context, recentBatches),
                  const SizedBox(height: 16),
                  _buildEfficiencyDistribution(context, recentBatches),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),
        
        // Additional Analytics
        _buildProfitabilityBreakdown(context),
      ],
    );
  }

  List<ProductionBatch> _getRecentBatches() {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToShow));
    return batches
        .where((batch) => batch.date.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Widget _buildKPICards(BuildContext context) {
    final stats = _calculateKPIs();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        
        if (isCompact) {
          // Mobile: 2x3 grid with premium cards
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: PremiumCard.kpi(
                    title: 'Total Batches',
                    value: stats['totalBatches'].toString(),
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppColors.primaryBlue,
                  )),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(child: PremiumCard.kpi(
                    title: 'Profitable',
                    value: stats['profitableBatches'].toString(),
                    icon: Icons.trending_up,
                    iconColor: AppColors.success,
                    valueColor: AppColors.success,
                  )),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              Row(
                children: [
                  Expanded(child: PremiumCard.kpi(
                    title: 'Average P&L',
                    value: '₹${stats['avgPnL'].toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.getPnLColor(stats['avgPnL'] as double),
                    valueColor: AppColors.getPnLColor(stats['avgPnL'] as double),
                  )),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(child: PremiumCard.kpi(
                    title: 'Avg Efficiency',
                    value: '${stats['avgEfficiency'].toStringAsFixed(1)}%',
                    icon: Icons.speed,
                    iconColor: AppColors.getEfficiencyColor(stats['avgEfficiency'] as double),
                    valueColor: AppColors.getEfficiencyColor(stats['avgEfficiency'] as double),
                  )),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              Row(
                children: [
                  Expanded(child: PremiumCard.kpi(
                    title: 'Best Day',
                    value: stats['bestDay'] as String,
                    icon: Icons.star_outline,
                    iconColor: AppColors.warning,
                    valueColor: AppColors.warning,
                  )),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(child: PremiumCard.kpi(
                    title: 'Success Rate',
                    value: '${stats['successRate'].toStringAsFixed(0)}%',
                    icon: Icons.verified_outlined,
                    iconColor: (stats['successRate'] as double) > 70 ? AppColors.success : AppColors.warning,
                    valueColor: (stats['successRate'] as double) > 70 ? AppColors.success : AppColors.warning,
                  )),
                ],
              ),
            ],
          );
        } else {
          // Desktop/Tablet: Single row with premium cards
          return Row(
            children: [
              Expanded(child: PremiumCard.kpi(
                title: 'Total Batches',
                value: stats['totalBatches'].toString(),
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.primaryBlue,
              )),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(child: PremiumCard.kpi(
                title: 'Profitable Batches',
                value: stats['profitableBatches'].toString(),
                icon: Icons.trending_up,
                iconColor: AppColors.success,
                valueColor: AppColors.success,
              )),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(child: PremiumCard.kpi(
                title: 'Average P&L',
                value: '₹${stats['avgPnL'].toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.getPnLColor(stats['avgPnL'] as double),
                valueColor: AppColors.getPnLColor(stats['avgPnL'] as double),
              )),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(child: PremiumCard.kpi(
                title: 'Avg Efficiency',
                value: '${stats['avgEfficiency'].toStringAsFixed(1)}%',
                icon: Icons.speed,
                iconColor: AppColors.getEfficiencyColor(stats['avgEfficiency'] as double),
                valueColor: AppColors.getEfficiencyColor(stats['avgEfficiency'] as double),
              )),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(child: PremiumCard.kpi(
                title: 'Best Performance',
                value: stats['bestDay'] as String,
                icon: Icons.star_outline,
                iconColor: AppColors.warning,
                valueColor: AppColors.warning,
              )),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(child: PremiumCard.kpi(
                title: 'Success Rate',
                value: '${stats['successRate'].toStringAsFixed(0)}%',
                icon: Icons.verified_outlined,
                iconColor: (stats['successRate'] as double) > 70 ? AppColors.success : AppColors.warning,
                valueColor: (stats['successRate'] as double) > 70 ? AppColors.success : AppColors.warning,
              )),
            ],
          );
        }
      },
    );
  }

  Widget _buildKPICard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitTrendChart(BuildContext context, List<ProductionBatch> recentBatches) {
    if (recentBatches.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Profit Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Need at least 2 batches to show trend',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final spots = recentBatches.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.netPnL);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profit Trend (Last ${recentBatches.length} Batches)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5000,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${(value / 1000).toInt()}k',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < recentBatches.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('MM/dd').format(recentBatches[index].date),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isProfit = spot.y > 0;
                          return FlDotCirclePainter(
                            radius: 4,
                            color: isProfit ? Colors.green : Colors.red,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyDistribution(BuildContext context, List<ProductionBatch> recentBatches) {
    if (recentBatches.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Efficiency Distribution',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No data available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Group batches by efficiency ranges
    final ranges = {
      'Low (0-3%)': 0,
      'Medium (3-6%)': 0,
      'High (6-10%)': 0,
      'Excellent (10%+)': 0,
    };

    for (final batch in recentBatches) {
      final efficiency = batch.pdEfficiency;
      if (efficiency < 3) {
        ranges['Low (0-3%)'] = ranges['Low (0-3%)']! + 1;
      } else if (efficiency < 6) {
        ranges['Medium (3-6%)'] = ranges['Medium (3-6%)']! + 1;
      } else if (efficiency < 10) {
        ranges['High (6-10%)'] = ranges['High (6-10%)']! + 1;
      } else {
        ranges['Excellent (10%+)'] = ranges['Excellent (10%+)']! + 1;
      }
    }

    final colors = [Colors.red, Colors.orange, Colors.blue, Colors.green];
    final sections = ranges.entries.map((entry) {
      final index = ranges.keys.toList().indexOf(entry.key);
      final percentage = (entry.value / recentBatches.length) * 100;
      
      return PieChartSectionData(
        color: colors[index],
        value: entry.value.toDouble(),
        title: entry.value > 0 ? '${percentage.toInt()}%' : '',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Efficiency Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ranges.entries.map((entry) {
                      final index = ranges.keys.toList().indexOf(entry.key);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              color: colors[index],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entry.key,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitabilityBreakdown(BuildContext context) {
    final stats = _calculateDetailedStats();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profitability Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                
                if (isCompact) {
                  return Column(
                    children: [
                      _buildBreakdownRow(context, 'Total Profit', '₹${(stats['totalProfit'] as double).toStringAsFixed(0)}', Colors.green),
                      _buildBreakdownRow(context, 'Total Loss', '₹${(stats['totalLoss'] as double).toStringAsFixed(0)}', Colors.red),
                      _buildBreakdownRow(context, 'Best Single Day', '₹${(stats['bestDay'] as double).toStringAsFixed(0)}', Colors.purple),
                      _buildBreakdownRow(context, 'Worst Single Day', '₹${(stats['worstDay'] as double).toStringAsFixed(0)}', Colors.orange),
                      _buildBreakdownRow(context, 'Avg Daily Revenue', '₹${(stats['avgRevenue'] as double).toStringAsFixed(0)}', Colors.blue),
                      _buildBreakdownRow(context, 'Avg Daily Costs', '₹${(stats['avgCosts'] as double).toStringAsFixed(0)}', Colors.grey),
                    ],
                  );
                } else {
                  return Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      _buildBreakdownItem(context, 'Total Profit', '₹${(stats['totalProfit'] as double).toStringAsFixed(0)}', Colors.green),
                      _buildBreakdownItem(context, 'Total Loss', '₹${(stats['totalLoss'] as double).toStringAsFixed(0)}', Colors.red),
                      _buildBreakdownItem(context, 'Best Single Day', '₹${(stats['bestDay'] as double).toStringAsFixed(0)}', Colors.purple),
                      _buildBreakdownItem(context, 'Worst Single Day', '₹${(stats['worstDay'] as double).toStringAsFixed(0)}', Colors.orange),
                      _buildBreakdownItem(context, 'Avg Daily Revenue', '₹${(stats['avgRevenue'] as double).toStringAsFixed(0)}', Colors.blue),
                      _buildBreakdownItem(context, 'Avg Daily Costs', '₹${(stats['avgCosts'] as double).toStringAsFixed(0)}', Colors.grey),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(BuildContext context, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(BuildContext context, String label, String value, Color color) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateKPIs() {
    if (batches.isEmpty) {
      return {
        'totalBatches': 0,
        'profitableBatches': 0,
        'avgPnL': 0.0,
        'avgEfficiency': 0.0,
        'bestDay': 'N/A',
        'successRate': 0.0,
      };
    }

    final totalBatches = batches.length;
    final profitableBatches = batches.where((b) => b.isProfitable).length;
    final avgPnL = batches.map((b) => b.netPnL).reduce((a, b) => a + b) / totalBatches;
    final avgEfficiency = batches.map((b) => b.pdEfficiency).reduce((a, b) => a + b) / totalBatches;
    final successRate = (profitableBatches / totalBatches) * 100;
    
    // Find best day (highest profit)
    final bestBatch = batches.reduce((a, b) => a.netPnL > b.netPnL ? a : b);
    final bestDay = DateFormat('MM/dd').format(bestBatch.date);

    return {
      'totalBatches': totalBatches,
      'profitableBatches': profitableBatches,
      'avgPnL': avgPnL,
      'avgEfficiency': avgEfficiency,
      'bestDay': bestDay,
      'successRate': successRate,
    };
  }

  Map<String, double> _calculateDetailedStats() {
    if (batches.isEmpty) {
      return {
        'totalProfit': 0.0,
        'totalLoss': 0.0,
        'bestDay': 0.0,
        'worstDay': 0.0,
        'avgRevenue': 0.0,
        'avgCosts': 0.0,
      };
    }

    final profitableBatches = batches.where((b) => b.isProfitable);
    final lossBatches = batches.where((b) => b.isLoss);
    
    final totalProfit = profitableBatches.isEmpty 
        ? 0.0 
        : profitableBatches.map((b) => b.netPnL).reduce((a, b) => a + b);
    
    final totalLoss = lossBatches.isEmpty 
        ? 0.0 
        : lossBatches.map((b) => b.netPnL.abs()).reduce((a, b) => a + b);
    
    final bestDay = batches.map((b) => b.netPnL).reduce((a, b) => a > b ? a : b);
    final worstDay = batches.map((b) => b.netPnL).reduce((a, b) => a < b ? a : b);
    
    final avgRevenue = batches.map((b) => b.totalIncome).reduce((a, b) => a + b) / batches.length;
    final avgCosts = batches.map((b) => b.totalExpenses).reduce((a, b) => a + b) / batches.length;

    return {
      'totalProfit': totalProfit,
      'totalLoss': totalLoss,
      'bestDay': bestDay,
      'worstDay': worstDay,
      'avgRevenue': avgRevenue,
      'avgCosts': avgCosts,
    };
  }
}