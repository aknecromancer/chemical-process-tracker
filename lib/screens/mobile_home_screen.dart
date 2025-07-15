import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/platform_storage_service.dart';
import '../models/production_batch.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_card.dart';
import 'mobile_batch_entry_screen.dart';
import 'mobile_batch_history_screen.dart';
import 'mobile_analytics_screen.dart';
import 'settings_screen.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const MobileDashboardTab(),
      const MobileBatchHistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Batches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class MobileDashboardTab extends StatefulWidget {
  const MobileDashboardTab({super.key});

  @override
  State<MobileDashboardTab> createState() => _MobileDashboardTabState();
}

class _MobileDashboardTabState extends State<MobileDashboardTab> {
  List<ProductionBatch> _recentBatches = [];
  ProductionBatch? _todaysBatch;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final batches = await PlatformStorageService.getAllBatches();
      final today = DateTime.now();
      
      // Check for today's batch
      final todaysBatch = batches.where((batch) {
        return batch.date.year == today.year &&
               batch.date.month == today.month &&
               batch.date.day == today.day;
      }).firstOrNull;
      
      setState(() {
        _recentBatches = batches.take(5).toList();
        _todaysBatch = todaysBatch;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading batches: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildTodaysStatus(),
            _buildQuickActions(),
            _buildBusinessAnalytics(),
            _buildRecentBatches(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryBlue.withValues(alpha: 0.1),
                AppColors.primaryBlue.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Chemical Process Tracker',
                  style: AppTheme.headlineMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  'Enterprise Edition',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_todaysBatch != null && _isDraftBatch(_todaysBatch!))
          Container(
            margin: const EdgeInsets.only(right: AppTheme.spacing8),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing8,
              vertical: AppTheme.spacing4,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: AppTheme.spacing4),
                Text(
                  'Draft',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
          icon: Icon(
            Icons.settings,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysStatus() {
    if (_todaysBatch == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final isDraft = _isDraftBatch(_todaysBatch!);
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: PremiumCard(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDraft 
                    ? [AppColors.warning.withValues(alpha: 0.1), AppColors.warning.withValues(alpha: 0.05)]
                    : [AppColors.successGreen.withValues(alpha: 0.1), AppColors.successGreen.withValues(alpha: 0.05)],
              ),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDraft ? Icons.edit_outlined : Icons.check_circle_outline,
                        color: isDraft ? AppColors.warning : AppColors.successGreen,
                        size: 24,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        isDraft ? 'Today\'s Batch - Draft' : 'Today\'s Batch - Completed',
                        style: AppTheme.titleMedium.copyWith(
                          color: isDraft ? AppColors.warning : AppColors.successGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    isDraft 
                        ? 'Continue working on today\'s batch entry'
                        : 'Today\'s batch has been completed',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isDraft) ...[
                    const SizedBox(height: AppTheme.spacing12),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToBatch(_todaysBatch!.date),
                      icon: const Icon(Icons.play_arrow, size: 20),
                      label: const Text('Continue Batch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: AppTheme.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: 'Today\'s Batch',
                    subtitle: 'Start today\'s entry',
                    icon: Icons.today_outlined,
                    color: AppColors.primaryBlue,
                    onTap: () => _navigateToNewBatch(),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: _buildActionCard(
                    title: 'Select Date',
                    subtitle: 'Custom date entry',
                    icon: Icons.calendar_today_outlined,
                    color: AppColors.info,
                    onTap: () => _navigateToCustomDateBatch(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessAnalytics() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: PremiumCard(
          onTap: () => _navigateToAnalytics(),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    Text(
                      'Business Analytics',
                      style: AppTheme.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  'View detailed performance metrics, cost analysis, and efficiency trends',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return PremiumCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              title,
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBatches() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Batches',
              style: AppTheme.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_recentBatches.isEmpty)
              _buildEmptyState()
            else
              ..._recentBatches.map((batch) => _buildBatchCard(batch)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'No batches yet',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Create your first batch to get started',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing16),
            ElevatedButton.icon(
              onPressed: () => _navigateToNewBatch(),
              icon: const Icon(Icons.add),
              label: const Text('Create Batch'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchCard(ProductionBatch batch) {
    final dateFormat = DateFormat('MMM d, y');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: PremiumCard(
        onTap: () => _navigateToBatch(batch.date),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(batch.date),
                      style: AppTheme.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    if (batch.calculationResult != null)
                      Text(
                        'P&L: ₹${batch.calculationResult!.finalProfitLoss.toStringAsFixed(2)}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: batch.calculationResult!.finalProfitLoss >= 0
                              ? AppColors.successGreen
                              : AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToNewBatch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileBatchEntryScreen(date: DateTime.now()),
      ),
    );
  }

  void _navigateToCustomDateBatch() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select batch date',
      cancelText: 'Cancel',
      confirmText: 'Create Batch',
    );
    
    if (selectedDate != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MobileBatchEntryScreen(date: selectedDate),
        ),
      );
    }
  }

  void _navigateToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MobileBatchHistoryScreen(),
      ),
    );
  }

  void _navigateToBatch(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileBatchEntryScreen(date: date),
      ),
    );
  }

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MobileAnalyticsScreen(),
      ),
    );
  }

  bool _isDraftBatch(ProductionBatch batch) {
    // A batch is considered draft if it has minimal data or incomplete calculations
    return batch.calculationResult == null || 
           batch.pattiQuantity == 0 || 
           batch.pattiRate == 0;
  }
}