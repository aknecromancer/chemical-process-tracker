import 'package:flutter/material.dart';
import '../services/lot_storage_service.dart';
import '../models/production_lot.dart';
import '../widgets/lot_analytics_dashboard.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<ProductionLot> _lots = [];
  bool _isLoading = true;
  int _selectedDays = 30;
  List<String> _selectedLotIds = [];
  bool _useSelectedLots = false;

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
          if (_lots.isNotEmpty)
            IconButton(
              onPressed: _showLotFilterDialog,
              icon: Stack(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: _useSelectedLots ? AppColors.successGreen : AppColors.primaryBlue,
                  ),
                  if (_useSelectedLots && _selectedLotIds.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
                child: Column(
                  children: [
                    if (_useSelectedLots && _selectedLotIds.isNotEmpty)
                      _buildSelectedLotsHeader(),
                    LotAnalyticsDashboard(
                      lots: _getFilteredLots(),
                      daysToShow: _selectedDays,
                      isCustomSelection: _useSelectedLots,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  List<ProductionLot> _getFilteredLots() {
    if (_useSelectedLots && _selectedLotIds.isNotEmpty) {
      return _lots.where((lot) => _selectedLotIds.contains(lot.id)).toList();
    }
    return _lots;
  }

  Widget _buildSelectedLotsHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
      child: PremiumCard(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                ),
                child: Icon(
                  Icons.filter_list,
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
                      'Custom LOT Selection',
                      style: AppTheme.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_selectedLotIds.length} LOT${_selectedLotIds.length != 1 ? 's' : ''} selected for analysis',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _useSelectedLots = false;
                    _selectedLotIds.clear();
                  });
                },
                icon: Icon(
                  Icons.clear,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
                label: Text(
                  'Clear Filter',
                  style: TextStyle(color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLotFilterDialog() async {
    final availableLots = _lots.toList()
      ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
    
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _LotSelectionDialog(
        availableLots: availableLots,
        selectedLotIds: _selectedLotIds,
      ),
    );
    
    if (result != null) {
      setState(() {
        _selectedLotIds = result;
        _useSelectedLots = result.isNotEmpty;
      });
    }
  }
}

class _LotSelectionDialog extends StatefulWidget {
  final List<ProductionLot> availableLots;
  final List<String> selectedLotIds;
  
  const _LotSelectionDialog({
    required this.availableLots,
    required this.selectedLotIds,
  });
  
  @override
  State<_LotSelectionDialog> createState() => _LotSelectionDialogState();
}

class _LotSelectionDialogState extends State<_LotSelectionDialog> {
  late List<String> _selectedLotIds;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _selectedLotIds = List.from(widget.selectedLotIds);
  }
  
  List<ProductionLot> get _filteredLots {
    if (_searchQuery.isEmpty) return widget.availableLots;
    
    return widget.availableLots.where((lot) {
      return lot.lotNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             lot.pattiDetails.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Text(
                    'Select LOTs for Analysis',
                    style: AppTheme.titleLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search LOTs by number or Patti details...',
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppTheme.spacing16),
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            
            Row(
              children: [
                Text(
                  '${_filteredLots.length} LOTs available',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (_selectedLotIds.isNotEmpty) ...[
                  Text(
                    '${_selectedLotIds.length} selected',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                ],
                TextButton(
                  onPressed: () => setState(() => _selectedLotIds.clear()),
                  child: Text('Clear All', style: TextStyle(color: AppColors.primaryBlue)),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedLotIds = _filteredLots.map((lot) => lot.id).toList();
                  }),
                  child: Text('Select All', style: TextStyle(color: AppColors.primaryBlue)),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                ),
                child: _filteredLots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: AppTheme.spacing12),
                            Text(
                              'No LOTs found',
                              style: AppTheme.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredLots.length,
                        itemBuilder: (context, index) {
                          final lot = _filteredLots[index];
                          final isSelected = _selectedLotIds.contains(lot.id);
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing8,
                              vertical: AppTheme.spacing4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.successGreen.withValues(alpha: 0.1) 
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                              border: isSelected 
                                  ? Border.all(color: AppColors.successGreen.withValues(alpha: 0.3))
                                  : null,
                            ),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedLotIds.add(lot.id);
                                  } else {
                                    _selectedLotIds.remove(lot.id);
                                  }
                                });
                              },
                              activeColor: AppColors.successGreen,
                              title: Text(
                                lot.lotNumber,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lot.pattiDetails,
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(lot.status).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getStatusText(lot.status),
                                          style: AppTheme.bodySmall.copyWith(
                                            color: _getStatusColor(lot.status),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (lot.isCompleted) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          'P&L: ₹${lot.netPnL.toStringAsFixed(0)}',
                                          style: AppTheme.bodySmall.copyWith(
                                            color: lot.isProfitable 
                                                ? AppColors.successGreen 
                                                : AppColors.error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selectedLotIds),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
                      ),
                    ),
                    child: Text(
                      'Apply Filter (${_selectedLotIds.length})',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(LotStatus status) {
    switch (status) {
      case LotStatus.draft:
        return AppColors.warning;
      case LotStatus.inProgress:
        return AppColors.primaryBlue;
      case LotStatus.completed:
        return AppColors.successGreen;
      case LotStatus.archived:
        return AppColors.textTertiary;
    }
  }
  
  String _getStatusText(LotStatus status) {
    switch (status) {
      case LotStatus.draft:
        return 'Draft';
      case LotStatus.inProgress:
        return 'In Progress';
      case LotStatus.completed:
        return 'Completed';
      case LotStatus.archived:
        return 'Archived';
    }
  }
}