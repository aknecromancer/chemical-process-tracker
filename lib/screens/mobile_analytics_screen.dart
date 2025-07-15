import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/platform_storage_service.dart';
import '../models/production_batch.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_card.dart';

class MobileAnalyticsScreen extends StatefulWidget {
  const MobileAnalyticsScreen({super.key});

  @override
  State<MobileAnalyticsScreen> createState() => _MobileAnalyticsScreenState();
}

class _MobileAnalyticsScreenState extends State<MobileAnalyticsScreen> {
  List<ProductionBatch> _batches = [];
  bool _isLoading = true;
  String _selectedPeriod = '30'; // days
  
  // Analytics data
  double _totalProfit = 0;
  double _totalCost = 0;
  double _totalRevenue = 0;
  double _avgEfficiency = 0;
  int _profitableBatches = 0;
  int _totalBatches = 0;
  double _bestProfit = 0;
  double _worstLoss = 0;
  
  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final allBatches = await PlatformStorageService.getAllBatches();
      final cutoffDate = DateTime.now().subtract(Duration(days: int.parse(_selectedPeriod)));
      
      final filteredBatches = allBatches.where((batch) => 
        batch.date.isAfter(cutoffDate) && batch.calculationResult != null
      ).toList();
      
      setState(() {
        _batches = filteredBatches;
        _calculateAnalytics();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  void _calculateAnalytics() {
    if (_batches.isEmpty) {
      _resetAnalytics();
      return;
    }
    
    _totalBatches = _batches.length;
    _totalProfit = 0;
    _totalCost = 0;
    _totalRevenue = 0;
    _profitableBatches = 0;
    _bestProfit = double.negativeInfinity;
    _worstLoss = double.infinity;
    double totalEfficiency = 0;
    int efficiencyCount = 0;
    
    for (final batch in _batches) {
      final result = batch.calculationResult!;
      
      _totalProfit += result.finalProfitLoss;
      _totalCost += result.totalCost;
      _totalRevenue += result.pdIncome + result.cuIncome;
      
      if (result.finalProfitLoss > 0) {
        _profitableBatches++;
      }
      
      if (result.finalProfitLoss > _bestProfit) {
        _bestProfit = result.finalProfitLoss;
      }
      
      if (result.finalProfitLoss < _worstLoss) {
        _worstLoss = result.finalProfitLoss;
      }
      
      // Calculate efficiency if PD quantity is available
      if (batch.pdQuantity != null && batch.pdQuantity! > 0) {
        final efficiency = (batch.pdQuantity! / batch.pattiQuantity) * 100;
        totalEfficiency += efficiency;
        efficiencyCount++;
      }
    }
    
    _avgEfficiency = efficiencyCount > 0 ? totalEfficiency / efficiencyCount : 0;
    
    // Handle edge cases
    if (_bestProfit == double.negativeInfinity) _bestProfit = 0;
    if (_worstLoss == double.infinity) _worstLoss = 0;
  }

  void _resetAnalytics() {
    _totalProfit = 0;
    _totalCost = 0;
    _totalRevenue = 0;
    _avgEfficiency = 0;
    _profitableBatches = 0;
    _totalBatches = 0;
    _bestProfit = 0;
    _worstLoss = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Business Analytics',
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadAnalytics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7', child: Text('Last 7 days')),
              const PopupMenuItem(value: '30', child: Text('Last 30 days')),
              const PopupMenuItem(value: '90', child: Text('Last 90 days')),
              const PopupMenuItem(value: '365', child: Text('Last year')),
            ],
            icon: Icon(Icons.date_range, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildAnalyticsContent(),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodHeader(),
          const SizedBox(height: AppTheme.spacing16),
          _buildOverviewMetrics(),
          const SizedBox(height: AppTheme.spacing16),
          _buildFinancialBreakdown(),
          const SizedBox(height: AppTheme.spacing16),
          _buildPerformanceMetrics(),
          const SizedBox(height: AppTheme.spacing16),
          _buildTrendAnalysis(),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader() {
    final periodText = _selectedPeriod == '7' ? 'Last 7 days' :
                     _selectedPeriod == '30' ? 'Last 30 days' :
                     _selectedPeriod == '90' ? 'Last 90 days' : 'Last year';
    
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
              child: Icon(
                Icons.analytics_outlined,
                color: AppColors.info,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Overview',
                    style: AppTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$periodText • $_totalBatches batches',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Overview',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Profit',
                value: '₹${_totalProfit.toStringAsFixed(0)}',
                icon: Icons.trending_up,
                color: _totalProfit >= 0 ? AppColors.successGreen : AppColors.error,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Revenue',
                value: '₹${_totalRevenue.toStringAsFixed(0)}',
                icon: Icons.monetization_on,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Cost',
                value: '₹${_totalCost.toStringAsFixed(0)}',
                icon: Icons.receipt,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _buildMetricCard(
                title: 'Success Rate',
                value: '${_totalBatches > 0 ? (_profitableBatches / _totalBatches * 100).toStringAsFixed(1) : 0}%',
                icon: Icons.check_circle,
                color: AppColors.successGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              value,
              style: AppTheme.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Breakdown',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        PremiumCard(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              children: [
                _buildBreakdownRow('Best Profit', _bestProfit, AppColors.successGreen),
                _buildBreakdownRow('Worst Loss', _worstLoss, AppColors.error),
                _buildBreakdownRow('Average P&L', _totalBatches > 0 ? _totalProfit / _totalBatches : 0, AppColors.info),
                if (_totalRevenue > 0)
                  _buildBreakdownRow('Profit Margin', (_totalProfit / _totalRevenue) * 100, AppColors.primaryBlue, isPercentage: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, double value, Color color, {bool isPercentage = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            isPercentage ? '${value.toStringAsFixed(1)}%' : '₹${value.toStringAsFixed(0)}',
            style: AppTheme.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        PremiumCard(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              children: [
                _buildPerformanceRow(
                  'Average Efficiency',
                  '${_avgEfficiency.toStringAsFixed(2)}%',
                  _getEfficiencyColor(_avgEfficiency),
                  Icons.speed,
                ),
                _buildPerformanceRow(
                  'Profitable Batches',
                  '$_profitableBatches of $_totalBatches',
                  AppColors.successGreen,
                  Icons.check_circle,
                ),
                _buildPerformanceRow(
                  'Production Volume',
                  '${_batches.fold(0.0, (sum, batch) => sum + batch.pattiQuantity).toStringAsFixed(0)} kg',
                  AppColors.rawMaterial,
                  Icons.inventory,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceRow(String label, String value, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTheme.labelLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendAnalysis() {
    if (_batches.length < 2) {
      return const SizedBox.shrink();
    }

    // Sort batches by date for trend analysis
    final sortedBatches = List<ProductionBatch>.from(_batches)
      ..sort((a, b) => a.date.compareTo(b.date));

    final recentBatches = sortedBatches.take(sortedBatches.length ~/ 2).toList();
    final olderBatches = sortedBatches.skip(sortedBatches.length ~/ 2).toList();

    final recentAvgProfit = recentBatches.fold(0.0, (sum, batch) => 
      sum + (batch.calculationResult?.finalProfitLoss ?? 0)) / recentBatches.length;
    final olderAvgProfit = olderBatches.fold(0.0, (sum, batch) => 
      sum + (batch.calculationResult?.finalProfitLoss ?? 0)) / olderBatches.length;

    final trend = recentAvgProfit - olderAvgProfit;
    final isImproving = trend > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trend Analysis',
          style: AppTheme.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        PremiumCard(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      isImproving ? Icons.trending_up : Icons.trending_down,
                      color: isImproving ? AppColors.successGreen : AppColors.error,
                      size: 24,
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Text(
                        isImproving ? 'Performance Improving' : 'Performance Declining',
                        style: AppTheme.titleMedium.copyWith(
                          color: isImproving ? AppColors.successGreen : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  'Recent average profit is ${isImproving ? 'higher' : 'lower'} by ₹${trend.abs().toStringAsFixed(0)} compared to earlier batches.',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 8.0) return AppColors.successGreen;
    if (efficiency >= 5.0) return AppColors.info;
    if (efficiency >= 2.0) return AppColors.warning;
    return AppColors.error;
  }
}