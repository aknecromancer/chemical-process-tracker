import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/lot_storage_service.dart';
import '../models/production_lot.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_card.dart';
import 'mobile_lot_entry_screen.dart';

class MobileLotManagementScreen extends StatefulWidget {
  const MobileLotManagementScreen({super.key});

  @override
  State<MobileLotManagementScreen> createState() => _MobileLotManagementScreenState();
}

class _MobileLotManagementScreenState extends State<MobileLotManagementScreen> {
  List<ProductionLot> _lots = [];
  List<ProductionLot> _filteredLots = [];
  bool _isLoading = true;
  String _searchQuery = '';
  LotStatus? _statusFilter;
  String _sortBy = 'startDate'; // 'startDate', 'completedDate', 'profit', 'lotNumber'
  bool _sortAscending = false;

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
        _filteredLots = lots;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading lots: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<ProductionLot> filtered = List.from(_lots);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((lot) {
        return lot.lotNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               lot.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;
      }).toList();
    }
    
    // Apply status filter
    if (_statusFilter != null) {
      filtered = filtered.where((lot) => lot.status == _statusFilter).toList();
    }
    
    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'startDate':
          comparison = a.startDate.compareTo(b.startDate);
          break;
        case 'completedDate':
          final aDate = a.completedDate ?? DateTime(1900);
          final bDate = b.completedDate ?? DateTime(1900);
          comparison = aDate.compareTo(bDate);
          break;
        case 'profit':
          comparison = a.netPnL.compareTo(b.netPnL);
          break;
        case 'lotNumber':
          comparison = a.lotNumber.compareTo(b.lotNumber);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
    
    setState(() {
      _filteredLots = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LOT Management',
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showCreateLotDialog,
            icon: Icon(
              Icons.add,
              color: AppColors.primaryBlue,
            ),
          ),
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
                  : _filteredLots.isEmpty
                      ? _buildEmptyState()
                      : _buildLotList(),
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
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'No LOTs found',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Create your first LOT to get started',
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing16),
            ElevatedButton.icon(
              onPressed: _showCreateLotDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create LOT'),
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
                hintText: 'Search LOTs...',
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
                _getStatusFilterLabel(),
                Icons.filter_alt,
                _showStatusFilterDialog,
              ),
              const Spacer(),
              Text(
                '${_filteredLots.length} LOTs',
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

  Widget _buildLotList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: _filteredLots.length,
      itemBuilder: (context, index) {
        final lot = _filteredLots[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
          child: _buildLotCard(lot),
        );
      },
    );
  }

  Widget _buildLotCard(ProductionLot lot) {
    final dateFormat = DateFormat('MMM d, y');
    
    return PremiumCard(
      onTap: () => _navigateToLot(lot),
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
                        lot.lotNumber,
                        style: AppTheme.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      _buildStatusChip(lot.status),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, lot),
                  itemBuilder: (context) => [
                    if (lot.status == LotStatus.draft)
                      PopupMenuItem(
                        value: 'start',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow, size: 16, color: AppColors.primaryBlue),
                            const SizedBox(width: AppTheme.spacing8),
                            const Text('Start LOT'),
                          ],
                        ),
                      ),
                    if (lot.status == LotStatus.inProgress)
                      PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: AppColors.successGreen),
                            const SizedBox(width: AppTheme.spacing8),
                            const Text('Complete LOT'),
                          ],
                        ),
                      ),
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
                    if (lot.status != LotStatus.completed)
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Started: ${dateFormat.format(lot.startDate)}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (lot.completedDate != null)
                        Text(
                          'Completed: ${dateFormat.format(lot.completedDate!)}',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (lot.calculationResult != null) ...[
                      Text(
                        'P&L: ₹${lot.netPnL.toStringAsFixed(0)}',
                        style: AppTheme.bodyMedium.copyWith(
                          color: lot.netPnL >= 0 ? AppColors.successGreen : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Efficiency: ${lot.pdEfficiency.toStringAsFixed(1)}%',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Patti: ${lot.pattiQuantity.toStringAsFixed(1)} kg',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(LotStatus status) {
    Color color;
    String text;
    IconData icon;
    
    switch (status) {
      case LotStatus.draft:
        color = AppColors.warning;
        text = 'Draft';
        icon = Icons.edit_outlined;
        break;
      case LotStatus.inProgress:
        color = AppColors.primaryBlue;
        text = 'In Progress';
        icon = Icons.play_arrow;
        break;
      case LotStatus.completed:
        color = AppColors.successGreen;
        text = 'Completed';
        icon = Icons.check_circle;
        break;
      case LotStatus.archived:
        color = AppColors.textTertiary;
        text = 'Archived';
        icon = Icons.archive;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing6,
        vertical: AppTheme.spacing2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: AppTheme.spacing4),
          Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLot(ProductionLot lot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MobileLotEntryScreen(lot: lot),
      ),
    ).then((value) => _loadLots()); // Refresh when returning
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'startDate':
        return 'Start Date';
      case 'completedDate':
        return 'Completed Date';
      case 'profit':
        return 'P&L';
      case 'lotNumber':
        return 'LOT Number';
      default:
        return 'Start Date';
    }
  }

  String _getStatusFilterLabel() {
    if (_statusFilter == null) return 'All Status';
    return _statusFilter!.displayName;
  }

  void _showCreateLotDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New LOT'),
        content: const Text('This will create a new production LOT in draft status.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _createNewLot();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewLot() async {
    try {
      final newLot = await LotStorageService.createNewLot();
      _navigateToLot(newLot);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating LOT: $e')),
        );
      }
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
              title: const Text('Start Date'),
              trailing: _sortBy == 'startDate' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _sortBy = 'startDate';
                  _sortAscending = false;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Completed Date'),
              trailing: _sortBy == 'completedDate' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _sortBy = 'completedDate';
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
              title: const Text('LOT Number'),
              trailing: _sortBy == 'lotNumber' ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _sortBy = 'lotNumber';
                  _sortAscending = true;
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

  void _showStatusFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Status'),
              trailing: _statusFilter == null ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _statusFilter = null;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            ...LotStatus.values.map((status) => ListTile(
              title: Text(status.displayName),
              trailing: _statusFilter == status ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() {
                  _statusFilter = status;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
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
                  _statusFilter = null;
                  _sortBy = 'startDate';
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
              leading: const Icon(Icons.filter_alt),
              title: const Text('Status Filter'),
              onTap: () {
                Navigator.pop(context);
                _showStatusFilterDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, ProductionLot lot) async {
    switch (action) {
      case 'start':
        await _startLot(lot);
        break;
      case 'complete':
        await _completeLot(lot);
        break;
      case 'edit':
        _navigateToLot(lot);
        break;
      case 'duplicate':
        await _duplicateLot(lot);
        break;
      case 'delete':
        await _deleteLot(lot);
        break;
    }
  }

  Future<void> _startLot(ProductionLot lot) async {
    try {
      await LotStorageService.markLotAsInProgress(lot.id);
      _loadLots();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('LOT ${lot.lotNumber} started successfully!'),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting LOT: $e')),
        );
      }
    }
  }

  Future<void> _completeLot(ProductionLot lot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete LOT'),
        content: Text('Are you sure you want to complete LOT ${lot.lotNumber}? This will mark it as completed with today\'s date.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await LotStorageService.completeLot(lot.id);
        _loadLots();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('LOT ${lot.lotNumber} completed successfully!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error completing LOT: $e')),
          );
        }
      }
    }
  }

  Future<void> _duplicateLot(ProductionLot lot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate LOT'),
        content: const Text('This will create a new LOT with the same data.'),
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
        final nextLotNumber = await LotStorageService.generateNextLotNumber();
        final newLot = await LotStorageService.createNewLot(
          lotNumber: nextLotNumber,
          pattiQuantity: lot.pattiQuantity,
          pattiRate: lot.pattiRate,
          customRates: Map.from(lot.customRates),
          manualEntries: List.from(lot.manualEntries),
        );
        
        _loadLots();
        _navigateToLot(newLot);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('LOT ${newLot.lotNumber} created successfully!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error duplicating LOT: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteLot(ProductionLot lot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete LOT'),
        content: Text('Are you sure you want to delete LOT ${lot.lotNumber}? This action cannot be undone.'),
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
        await LotStorageService.deleteLot(lot.id);
        _loadLots();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('LOT ${lot.lotNumber} deleted successfully!'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting LOT: $e')),
          );
        }
      }
    }
  }
}