import 'package:flutter/material.dart';
import '../services/lot_storage_service.dart';
import '../models/production_lot.dart';
import '../widgets/lot_analytics_dashboard.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<ProductionLot> _lots = [];
  bool _isLoading = true;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _loadLots();
  }

  Future<void> _loadLots() async {
    try {
      final lots = await LotStorageService.getAllLots();
      setState(() {
        _lots = lots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics',
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: AppTheme.lightSystemUiOverlay,
        actions: [
          PopupMenuButton<int>(
            onSelected: (days) {
              setState(() {
                _selectedDays = days;
              });
            },
            icon: Icon(
              Icons.date_range,
              color: AppColors.primaryBlue,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 7,
                child: Row(
                  children: [
                    Icon(
                      Icons.today,
                      size: 16,
                      color: _selectedDays == 7 ? AppColors.primaryBlue : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last 7 Days',
                      style: TextStyle(
                        color: _selectedDays == 7 ? AppColors.primaryBlue : AppColors.textPrimary,
                        fontWeight: _selectedDays == 7 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (_selectedDays == 7) ...[
                      const Spacer(),
                      Icon(Icons.check, size: 16, color: AppColors.primaryBlue),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 30,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 16,
                      color: _selectedDays == 30 ? AppColors.primaryBlue : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last 30 Days',
                      style: TextStyle(
                        color: _selectedDays == 30 ? AppColors.primaryBlue : AppColors.textPrimary,
                        fontWeight: _selectedDays == 30 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (_selectedDays == 30) ...[
                      const Spacer(),
                      Icon(Icons.check, size: 16, color: AppColors.primaryBlue),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 90,
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 16,
                      color: _selectedDays == 90 ? AppColors.primaryBlue : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last 90 Days',
                      style: TextStyle(
                        color: _selectedDays == 90 ? AppColors.primaryBlue : AppColors.textPrimary,
                        fontWeight: _selectedDays == 90 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (_selectedDays == 90) ...[
                      const Spacer(),
                      Icon(Icons.check, size: 16, color: AppColors.primaryBlue),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 365,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: _selectedDays == 365 ? AppColors.primaryBlue : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last Year',
                      style: TextStyle(
                        color: _selectedDays == 365 ? AppColors.primaryBlue : AppColors.textPrimary,
                        fontWeight: _selectedDays == 365 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (_selectedDays == 365) ...[
                      const Spacer(),
                      Icon(Icons.check, size: 16, color: AppColors.primaryBlue),
                    ],
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: _loadLots,
            icon: Icon(
              Icons.refresh,
              color: AppColors.primaryBlue,
            ),
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                child: LotAnalyticsDashboard(
                  lots: _lots,
                  daysToShow: _selectedDays,
                ),
              ),
      ),
    );
  }
}