import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/lot_storage_service.dart';
import '../models/production_lot.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_card.dart';
import 'mobile_lot_management_screen.dart';
import 'mobile_lot_entry_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const LotDashboardTab(),
    const MobileLotManagementScreen(),
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTheme.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTheme.bodySmall,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'LOTs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class LotDashboardTab extends StatefulWidget {
  const LotDashboardTab({super.key});

  @override
  State<LotDashboardTab> createState() => _LotDashboardTabState();
}

class _LotDashboardTabState extends State<LotDashboardTab> {
  List<ProductionLot> _lots = [];
  List<ProductionLot> _activeLots = [];
  List<ProductionLot> _recentCompletedLots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final allLots = await LotStorageService.getAllLots();
      final activeLots = await LotStorageService.getActiveLots();
      final recentCompleted = await LotStorageService.getRecentCompletedLots(7);
      
      setState(() {
        _lots = allLots;
        _activeLots = activeLots;
        _recentCompletedLots = recentCompleted.take(5).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createNewLot() async {
    try {
      final newLot = await LotStorageService.createNewLot();
      await _loadData();
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MobileLotEntryScreen(lot: newLot),
          ),
        ).then((_) => _loadData());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating LOT: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d, y');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chemical Process Tracker',
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: AppTheme.lightSystemUiOverlay,
        actions: [
          IconButton(
            onPressed: _createNewLot,
            icon: Icon(
              Icons.add,
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
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primaryBlue,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Header
                      Text(
                        dateFormat.format(today),
                        style: AppTheme.headlineSmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing24),

                      // Active LOTs Section
                      _buildActiveLotSection(),
                      const SizedBox(height: AppTheme.spacing24),

                      // Quick Stats
                      _buildQuickStats(),
                      const SizedBox(height: AppTheme.spacing24),

                      // Recent Completed LOTs
                      _buildRecentCompletedLots(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildActiveLotSection() {
    if (_activeLots.isEmpty) {
      return PremiumCard(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  size: 48,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'No Active LOTs',
                style: AppTheme.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Create a new production LOT to start tracking materials, costs, and production efficiency.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
              ElevatedButton.icon(
                onPressed: _createNewLot,
                icon: const Icon(Icons.add),
                label: const Text('Create New LOT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing20,
                    vertical: AppTheme.spacing12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active LOTs',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MobileLotManagementScreen(),
                  ),
                ).then((_) => _loadData());
              },
              child: Text(
                'View All',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        ..._activeLots.take(3).map((lot) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
          child: _buildActiveLotCard(lot),
        )),
      ],
    );
  }

  Widget _buildActiveLotCard(ProductionLot lot) {
    final dateFormat = DateFormat('MMM d');
    
    return PremiumCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MobileLotEntryScreen(lot: lot),
          ),
        ).then((_) => _loadData());
      },
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: lot.status == LotStatus.inProgress 
                    ? AppColors.primaryBlue.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              ),
              child: Icon(
                lot.status == LotStatus.inProgress 
                    ? Icons.play_arrow 
                    : Icons.edit_outlined,
                color: lot.status == LotStatus.inProgress 
                    ? AppColors.primaryBlue 
                    : AppColors.warning,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        lot.lotNumber,
                        style: AppTheme.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacing6,
                          vertical: AppTheme.spacing2,
                        ),
                        decoration: BoxDecoration(
                          color: lot.status == LotStatus.inProgress 
                              ? AppColors.primaryBlue 
                              : AppColors.warning,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
                        ),
                        child: Text(
                          lot.statusDisplayName,
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    'Started: ${dateFormat.format(lot.startDate)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (lot.status == LotStatus.inProgress)
                    Text(
                      'Duration: ${lot.durationInDays} days',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final completedLots = _lots.where((lot) => lot.isCompleted).toList();
    final profitableLots = completedLots.where((lot) => lot.isProfitable).length;
    final avgEfficiency = completedLots.isEmpty 
        ? 0.0 
        : completedLots.map((lot) => lot.pdEfficiency).reduce((a, b) => a + b) / completedLots.length;
    final avgPnL = completedLots.isEmpty 
        ? 0.0 
        : completedLots.map((lot) => lot.netPnL).reduce((a, b) => a + b) / completedLots.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: AppTheme.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          children: [
            Expanded(
              child: PremiumCard.kpi(
                title: 'Total LOTs',
                value: _lots.length.toString(),
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: PremiumCard.kpi(
                title: 'Active',
                value: _activeLots.length.toString(),
                icon: Icons.play_arrow,
                iconColor: AppColors.primaryBlue,
                valueColor: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          children: [
            Expanded(
              child: PremiumCard.kpi(
                title: 'Profitable',
                value: profitableLots.toString(),
                icon: Icons.trending_up,
                iconColor: AppColors.successGreen,
                valueColor: AppColors.successGreen,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: PremiumCard.kpi(
                title: 'Avg P&L',
                value: '₹${avgPnL.toStringAsFixed(0)}',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.getPnLColor(avgPnL),
                valueColor: AppColors.getPnLColor(avgPnL),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentCompletedLots() {
    if (_recentCompletedLots.isEmpty) {
      return PremiumCard(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'No Completed LOTs',
                style: AppTheme.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Complete your first LOT to see recent completion history.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recently Completed',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AnalyticsScreen(),
                  ),
                );
              },
              child: Text(
                'View Analytics',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        ..._recentCompletedLots.map((lot) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
          child: _buildCompletedLotCard(lot),
        )),
      ],
    );
  }

  Widget _buildCompletedLotCard(ProductionLot lot) {
    final dateFormat = DateFormat('MMM d');
    
    return PremiumCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MobileLotEntryScreen(lot: lot),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppColors.successGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot.lotNumber,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Completed: ${dateFormat.format(lot.completedDate!)}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${lot.netPnL.toStringAsFixed(0)}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: lot.isProfitable ? AppColors.successGreen : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${lot.pdEfficiency.toStringAsFixed(1)}%',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppTheme.spacing8),
            Icon(
              lot.isProfitable ? Icons.trending_up : Icons.trending_down,
              color: lot.isProfitable ? AppColors.successGreen : AppColors.error,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}