import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/platform_storage_service.dart';
import '../models/production_batch.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_card.dart';
import 'mobile_batch_entry_screen.dart';

class MobileBatchHistoryScreen extends StatefulWidget {
  const MobileBatchHistoryScreen({super.key});

  @override
  State<MobileBatchHistoryScreen> createState() => _MobileBatchHistoryScreenState();
}

class _MobileBatchHistoryScreenState extends State<MobileBatchHistoryScreen> {
  List<ProductionBatch> _batches = [];
  List<ProductionBatch> _filteredBatches = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'profit', 'quantity'
  bool _sortAscending = false;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    try {
      final batches = await PlatformStorageService.getAllBatches();
      setState(() {
        _batches = batches;
        _filteredBatches = batches;
        _isLoading = false;
      });
      _applyFilters();
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

  void _applyFilters() {
    List<ProductionBatch> filtered = List.from(_batches);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((batch) {
        final dateStr = DateFormat('MMM d, y').format(batch.date);
        return dateStr.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Apply date range filter
    if (_dateRange != null) {
      filtered = filtered.where((batch) {
        return batch.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
               batch.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    
    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          comparison = a.date.compareTo(b.date);
          break;
        case 'profit':
          final aProfit = a.calculationResult?.finalProfitLoss ?? 0;
          final bProfit = b.calculationResult?.finalProfitLoss ?? 0;
          comparison = aProfit.compareTo(bProfit);
          break;
        case 'quantity':
          comparison = a.pattiQuantity.compareTo(b.pattiQuantity);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
    
    setState(() {
      _filteredBatches = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Batch History',
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: Icon(
              Icons.filter_list,
              color: AppColors.textSecondary,
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
        child: Column(
          children: [
            _buildSearchAndFilters(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredBatches.isEmpty
                      ? _buildEmptyState()
                      : _buildBatchList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'No batches found',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Create your first batch to see it here',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
              decoration: InputDecoration(
                hintText: 'Search batches...',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing12,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          // Filter chips
          Row(
            children: [
              _buildFilterChip(
                'Sort: ${_getSortLabel()}',
                Icons.sort,
                _showSortDialog,
              ),
              const SizedBox(width: AppTheme.spacing8),
              _buildFilterChip(
                _dateRange == null ? 'Date Range' : 'Custom Range',
                Icons.date_range,
                _showDateRangeDialog,
              ),
              const Spacer(),
              Text(
                '${_filteredBatches.length} batches',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing6,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryBlue),
            const SizedBox(width: AppTheme.spacing4),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: _filteredBatches.length,
      itemBuilder: (context, index) {
        final batch = _filteredBatches[index];
        final dateFormat = DateFormat('MMM d, y');
        final isDraft = _isDraftBatch(batch);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
          child: PremiumCard(
            onTap: () => _navigateToBatch(batch.date),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              dateFormat.format(batch.date),
                              style: AppTheme.titleMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacing8),
                            _buildStatusChip(isDraft),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleMenuAction(value, batch),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: AppTheme.spacing8),
                                const Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.content_copy, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: AppTheme.spacing8),
                                const Text('Duplicate'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: AppColors.error),
                                const SizedBox(width: AppTheme.spacing8),
                                Text('Delete', style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                        icon: Icon(
                          Icons.more_vert,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Row(
                    children: [
                      _buildInfoChip(
                        'Patti: ${batch.pattiQuantity.toStringAsFixed(1)} kg',
                        AppColors.rawMaterial,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      if (batch.calculationResult != null)
                        _buildInfoChip(
                          'P&L: ₹${batch.calculationResult!.finalProfitLoss.toStringAsFixed(0)}',
                          batch.calculationResult!.finalProfitLoss >= 0
                              ? AppColors.successGreen
                              : AppColors.error,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(bool isDraft) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing6,
        vertical: AppTheme.spacing2,
      ),
      decoration: BoxDecoration(
        color: isDraft 
            ? AppColors.warning.withValues(alpha: 0.1)
            : AppColors.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDraft ? Icons.edit : Icons.check_circle,
            size: 12,
            color: isDraft ? AppColors.warning : AppColors.successGreen,
          ),
          const SizedBox(width: AppTheme.spacing4),
          Text(
            isDraft ? 'Draft' : 'Complete',
            style: AppTheme.bodySmall.copyWith(
              color: isDraft ? AppColors.warning : AppColors.successGreen,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
      ),
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
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

  bool _isDraftBatch(ProductionBatch batch) {
    return batch.calculationResult == null || 
           batch.pattiQuantity == 0 || 
           batch.pattiRate == 0;
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'date':
        return 'Date';
      case 'profit':
        return 'P&L';
      case 'quantity':
        return 'Quantity';
      default:
        return 'Date';
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Date'),
              trailing: _sortBy == 'date' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _sortBy = 'date';
                  _sortAscending = false;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('P&L'),
              trailing: _sortBy == 'profit' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _sortBy = 'profit';
                  _sortAscending = false;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Quantity'),
              trailing: _sortBy == 'quantity' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _sortBy = 'quantity';
                  _sortAscending = false;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDateRangeDialog() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      _applyFilters();
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear All Filters'),
              onTap: () {
                setState(() {
                  _searchQuery = '';
                  _dateRange = null;
                  _sortBy = 'date';
                  _sortAscending = false;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sort),
              title: const Text('Sort Options'),
              onTap: () {
                Navigator.pop(context);
                _showSortDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Date Range'),
              onTap: () {
                Navigator.pop(context);
                _showDateRangeDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, ProductionBatch batch) async {
    switch (action) {
      case 'edit':
        _navigateToBatch(batch.date);
        break;
      case 'duplicate':
        await _duplicateBatch(batch);
        break;
      case 'delete':
        await _deleteBatch(batch);
        break;
    }
  }

  Future<void> _duplicateBatch(ProductionBatch batch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Batch'),
        content: const Text('This will create a new batch with the same data for today\'s date.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final newBatch = ProductionBatch(
          date: DateTime.now(),
          pattiQuantity: batch.pattiQuantity,
          pattiRate: batch.pattiRate,
          pdQuantity: batch.pdQuantity,
          customRates: batch.customRates,
          manualEntries: batch.manualEntries,
          calculationResult: null, // Will be recalculated
          createdAt: DateTime.now(),
        );
        
        await PlatformStorageService.saveBatch(newBatch);
        _loadBatches();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Batch duplicated successfully!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error duplicating batch: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteBatch(ProductionBatch batch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Batch'),
        content: const Text('Are you sure you want to delete this batch? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await PlatformStorageService.deleteBatch(batch.date);
        _loadBatches();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Batch deleted successfully!'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting batch: $e')),
          );
        }
      }
    }
  }
}