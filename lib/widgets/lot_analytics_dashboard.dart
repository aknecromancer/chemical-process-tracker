import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/production_lot.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import 'premium_card.dart';

class LotAnalyticsDashboard extends StatelessWidget {
  final List<ProductionLot> lots;
  final int daysToShow;

  const LotAnalyticsDashboard({
    super.key,
    required this.lots,
    this.daysToShow = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (lots.isEmpty) {
      return PremiumCard(
        padding: const EdgeInsets.all(AppTheme.spacing40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing20),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
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
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'Complete production LOTs to unlock powerful analytics and business insights',
              textAlign: TextAlign.center,
              style: AppTheme.bodyLarge.copyWith(
                color: AppColors.textSecondary,
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
                      AppColors.primaryBlue.withValues(alpha: 0.1),
                      AppColors.primaryBlue.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
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
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: AppColors.primaryBlue,
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
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing2),
                          Text(
                            'Analytics appear after your first completed LOT',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.primaryBlue.withValues(alpha: 0.8),
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

    final completedLots = _getCompletedLots();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        PremiumCardHeader(
          title: 'LOT-Based Analytics',
          subtitle: 'Performance insights based on LOT completion dates',
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
                    child: _buildProfitTrendChart(context, completedLots),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEfficiencyDistribution(context, completedLots),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildProfitTrendChart(context, completedLots),
                  const SizedBox(height: 16),
                  _buildEfficiencyDistribution(context, completedLots),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),
        
        // Additional Analytics
        _buildLotStatusBreakdown(context),
        const SizedBox(height: 16),
        _buildProfitabilityBreakdown(context),
      ],
    );
  }

  List<ProductionLot> _getCompletedLots() {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToShow));
    return lots
        .where((lot) => lot.isCompleted && lot.completedDate != null)
        .where((lot) => lot.completedDate!.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => a.completedDate!.compareTo(b.completedDate!));
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
                    title: 'Total LOTs',
                    value: stats['totalLots'].toString(),
                    icon: Icons.inventory_2_outlined,
                    iconColor: AppColors.primaryBlue,
                  )),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(child: PremiumCard.kpi(
                    title: 'Completed',
                    value: stats['completedLots'].toString(),
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.successGreen,
                    valueColor: AppColors.successGreen,
                  )),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              Row(
                children: [
                  Expanded(child: PremiumCard.kpi(
                    title: 'Profitable',
                    value: stats['profitableLots'].toString(),
                    icon: Icons.trending_up,
                    iconColor: AppColors.successGreen,
                    valueColor: AppColors.successGreen,
                  )),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(child: PremiumCard.kpi(
                    title: 'In Progress',
                    value: stats['activeLots'].toString(),
                    icon: Icons.play_arrow,
                    iconColor: AppColors.primaryBlue,
                    valueColor: AppColors.primaryBlue,
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
            ],
          );
        } else {
          // Desktop/Tablet: Single row with premium cards
          return Row(
            children: [
              Expanded(child: PremiumCard.kpi(
                title: 'Total LOTs',
                value: stats['totalLots'].toString(),
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.primaryBlue,
              )),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(child: PremiumCard.kpi(
                title: 'Completed LOTs',
                value: stats['completedLots'].toString(),
                icon: Icons.check_circle_outline,
                iconColor: AppColors.successGreen,
                valueColor: AppColors.successGreen,
              )),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(child: PremiumCard.kpi(
                title: 'Profitable LOTs',
                value: stats['profitableLots'].toString(),
                icon: Icons.trending_up,
                iconColor: AppColors.successGreen,
                valueColor: AppColors.successGreen,
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
                title: 'Success Rate',
                value: '${stats['successRate'].toStringAsFixed(0)}%',
                icon: Icons.verified_outlined,
                iconColor: (stats['successRate'] as double) > 70 ? AppColors.successGreen : AppColors.warning,
                valueColor: (stats['successRate'] as double) > 70 ? AppColors.successGreen : AppColors.warning,
              )),
            ],
          );
        }
      },
    );
  }

  Widget _buildProfitTrendChart(BuildContext context, List<ProductionLot> completedLots) {
    if (completedLots.length < 2) {
      return PremiumCard(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          child: Column(
            children: [
              Text(
                'Profit Trend',
                style: AppTheme.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
              Icon(
                Icons.trending_up,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'Need at least 2 completed LOTs to show trend',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final spots = completedLots.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.netPnL);
    }).toList();

    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profit Trend (Last ${completedLots.length} Completed LOTs)',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5000,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${(value / 1000).toInt()}k',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.textSecondary,
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
                          if (index >= 0 && index < completedLots.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                completedLots[index].lotNumber,
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
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
                      color: AppColors.primaryBlue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isProfit = spot.y > 0;
                          return FlDotCirclePainter(
                            radius: 4,
                            color: isProfit ? AppColors.successGreen : AppColors.error,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
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

  Widget _buildEfficiencyDistribution(BuildContext context, List<ProductionLot> completedLots) {
    if (completedLots.isEmpty) {
      return PremiumCard(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          child: Column(
            children: [
              Text(
                'Efficiency Distribution',
                style: AppTheme.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'No completed LOTs available',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group LOTs by efficiency ranges
    final ranges = {
      'Low (0-3%)': 0,
      'Medium (3-6%)': 0,
      'High (6-10%)': 0,
      'Excellent (10%+)': 0,
    };

    for (final lot in completedLots) {
      final efficiency = lot.pdEfficiency;
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

    final colors = [AppColors.error, AppColors.warning, AppColors.primaryBlue, AppColors.successGreen];
    final sections = ranges.entries.map((entry) {
      final index = ranges.keys.toList().indexOf(entry.key);
      final percentage = completedLots.isNotEmpty ? (entry.value / completedLots.length) * 100 : 0;
      
      return PieChartSectionData(
        color: colors[index],
        value: entry.value.toDouble(),
        title: entry.value > 0 ? '${percentage.toInt()}%' : '',
        radius: 50,
        titleStyle: AppTheme.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Efficiency Distribution',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
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
                  const SizedBox(width: AppTheme.spacing20),
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
                              style: AppTheme.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
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

  Widget _buildLotStatusBreakdown(BuildContext context) {
    final statusCounts = {
      'Draft': lots.where((lot) => lot.status == LotStatus.draft).length,
      'In Progress': lots.where((lot) => lot.status == LotStatus.inProgress).length,
      'Completed': lots.where((lot) => lot.status == LotStatus.completed).length,
      'Archived': lots.where((lot) => lot.status == LotStatus.archived).length,
    };

    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LOT Status Breakdown',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Column(
              children: statusCounts.entries.map((entry) {
                Color color;
                IconData icon;
                
                switch (entry.key) {
                  case 'Draft':
                    color = AppColors.warning;
                    icon = Icons.edit_outlined;
                    break;
                  case 'In Progress':
                    color = AppColors.primaryBlue;
                    icon = Icons.play_arrow;
                    break;
                  case 'Completed':
                    color = AppColors.successGreen;
                    icon = Icons.check_circle;
                    break;
                  case 'Archived':
                    color = AppColors.textTertiary;
                    icon = Icons.archive;
                    break;
                  default:
                    color = AppColors.textSecondary;
                    icon = Icons.help_outline;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacing8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        ),
                        child: Icon(icon, size: 20, color: color),
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing12,
                          vertical: AppTheme.spacing4,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                        ),
                        child: Text(
                          entry.value.toString(),
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitabilityBreakdown(BuildContext context) {
    final stats = _calculateDetailedStats();
    
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profitability Breakdown',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 600;
                
                if (isCompact) {
                  return Column(
                    children: [
                      _buildBreakdownRow(context, 'Total Profit', '₹${(stats['totalProfit'] as double).toStringAsFixed(0)}', AppColors.successGreen),
                      _buildBreakdownRow(context, 'Total Loss', '₹${(stats['totalLoss'] as double).toStringAsFixed(0)}', AppColors.error),
                      _buildBreakdownRow(context, 'Best LOT', '₹${(stats['bestLot'] as double).toStringAsFixed(0)}', AppColors.primaryBlue),
                      _buildBreakdownRow(context, 'Worst LOT', '₹${(stats['worstLot'] as double).toStringAsFixed(0)}', AppColors.warning),
                      _buildBreakdownRow(context, 'Avg Revenue', '₹${(stats['avgRevenue'] as double).toStringAsFixed(0)}', AppColors.primaryBlue),
                      _buildBreakdownRow(context, 'Avg Duration', '${(stats['avgDuration'] as double).toStringAsFixed(1)} days', AppColors.textSecondary),
                    ],
                  );
                } else {
                  return Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      _buildBreakdownItem(context, 'Total Profit', '₹${(stats['totalProfit'] as double).toStringAsFixed(0)}', AppColors.successGreen),
                      _buildBreakdownItem(context, 'Total Loss', '₹${(stats['totalLoss'] as double).toStringAsFixed(0)}', AppColors.error),
                      _buildBreakdownItem(context, 'Best LOT', '₹${(stats['bestLot'] as double).toStringAsFixed(0)}', AppColors.primaryBlue),
                      _buildBreakdownItem(context, 'Worst LOT', '₹${(stats['worstLot'] as double).toStringAsFixed(0)}', AppColors.warning),
                      _buildBreakdownItem(context, 'Avg Revenue', '₹${(stats['avgRevenue'] as double).toStringAsFixed(0)}', AppColors.primaryBlue),
                      _buildBreakdownItem(context, 'Avg Duration', '${(stats['avgDuration'] as double).toStringAsFixed(1)} days', AppColors.textSecondary),
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
          Text(
            label, 
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
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
            style: AppTheme.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateKPIs() {
    if (lots.isEmpty) {
      return {
        'totalLots': 0,
        'completedLots': 0,
        'profitableLots': 0,
        'activeLots': 0,
        'avgPnL': 0.0,
        'avgEfficiency': 0.0,
        'successRate': 0.0,
      };
    }

    final totalLots = lots.length;
    final completedLots = lots.where((lot) => lot.isCompleted).toList();
    final profitableLots = completedLots.where((lot) => lot.isProfitable).length;
    final activeLots = lots.where((lot) => lot.isActive).length;
    
    final avgPnL = completedLots.isEmpty 
        ? 0.0 
        : completedLots.map((lot) => lot.netPnL).reduce((a, b) => a + b) / completedLots.length;
    
    final avgEfficiency = completedLots.isEmpty 
        ? 0.0 
        : completedLots.map((lot) => lot.pdEfficiency).reduce((a, b) => a + b) / completedLots.length;
    
    final successRate = completedLots.isEmpty 
        ? 0.0 
        : (profitableLots / completedLots.length) * 100;

    return {
      'totalLots': totalLots,
      'completedLots': completedLots.length,
      'profitableLots': profitableLots,
      'activeLots': activeLots,
      'avgPnL': avgPnL,
      'avgEfficiency': avgEfficiency,
      'successRate': successRate,
    };
  }

  Map<String, double> _calculateDetailedStats() {
    final completedLots = lots.where((lot) => lot.isCompleted).toList();
    
    if (completedLots.isEmpty) {
      return {
        'totalProfit': 0.0,
        'totalLoss': 0.0,
        'bestLot': 0.0,
        'worstLot': 0.0,
        'avgRevenue': 0.0,
        'avgDuration': 0.0,
      };
    }

    final profitableLots = completedLots.where((lot) => lot.isProfitable);
    final lossLots = completedLots.where((lot) => lot.isLoss);
    
    final totalProfit = profitableLots.isEmpty 
        ? 0.0 
        : profitableLots.map((lot) => lot.netPnL).reduce((a, b) => a + b);
    
    final totalLoss = lossLots.isEmpty 
        ? 0.0 
        : lossLots.map((lot) => lot.netPnL.abs()).reduce((a, b) => a + b);
    
    final bestLot = completedLots.map((lot) => lot.netPnL).reduce((a, b) => a > b ? a : b);
    final worstLot = completedLots.map((lot) => lot.netPnL).reduce((a, b) => a < b ? a : b);
    
    final avgRevenue = completedLots.map((lot) => lot.totalIncome).reduce((a, b) => a + b) / completedLots.length;
    final avgDuration = completedLots.map((lot) => lot.durationInDays.toDouble()).reduce((a, b) => a + b) / completedLots.length;

    return {
      'totalProfit': totalProfit,
      'totalLoss': totalLoss,
      'bestLot': bestLot,
      'worstLot': worstLot,
      'avgRevenue': avgRevenue,
      'avgDuration': avgDuration,
    };
  }
}