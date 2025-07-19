import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/production_lot.dart';
import '../models/material_template.dart';
import '../models/configurable_defaults.dart';
import '../services/lot_storage_service.dart';
import '../services/calculation_engine.dart';
import '../services/cloud_storage_service.dart';
import '../services/mobile_storage_service.dart';
import '../widgets/premium_card.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';

class MobileLotEntryScreen extends StatefulWidget {
  final ProductionLot? lot;

  const MobileLotEntryScreen({super.key, this.lot});

  @override
  State<MobileLotEntryScreen> createState() => _MobileLotEntryScreenState();
}

class _MobileLotEntryScreenState extends State<MobileLotEntryScreen> 
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _lotNumberController = TextEditingController();
  final _pattiQuantityController = TextEditingController();
  final _pattiRateController = TextEditingController();
  final _pdQuantityController = TextEditingController();
  final _notesController = TextEditingController();

  late ProductionLot _lot;
  List<Map<String, dynamic>> _manualEntries = [];
  Map<String, double> _customRates = {};
  bool _isLoading = false;
  bool _isSaving = false;
  CalculationResult? _calculationResult;
  AdvancedCalculationEngine? _calculationEngine;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeLot();
    _initializeCalculationEngine();
    
    // Add listener to refresh calculations when switching tabs
    _tabController.addListener(() {
      if (_tabController.index == 1) { // Materials tab
        _calculateResults(); // Refresh materials calculations
      }
    });
  }

  void _initializeLot() {
    if (widget.lot != null) {
      _lot = widget.lot!;
      _lotNumberController.text = _lot.lotNumber;
      _pattiQuantityController.text = _lot.pattiQuantity.toString();
      _pattiRateController.text = _lot.pattiRate.toString();
      _pdQuantityController.text = _lot.pdQuantity?.toString() ?? '';
      _notesController.text = _lot.notes ?? '';
      _manualEntries = List.from(_lot.manualEntries);
      _customRates = Map.from(_lot.customRates);
      _calculationResult = _lot.calculationResult;
    } else {
      _lot = ProductionLot(
        lotNumber: 'NEW',
        startDate: DateTime.now(),
        status: LotStatus.draft,
        pattiQuantity: 0.0,
        pattiRate: 0.0,
        customRates: {},
        rateSnapshot: {}, // Will be populated when defaults are loaded
        manualEntries: [],
      );
      _lotNumberController.text = 'NEW';
    }
  }

  Future<void> _initializeCalculationEngine() async {
    try {
      final defaults = await MobileStorageService.getDefaults();
      
      if (defaults != null) {
        _calculationEngine = AdvancedCalculationEngine(defaults);
        
        // For new LOTs only, capture rate snapshot from current defaults
        if (_lot.rateSnapshot.isEmpty && widget.lot == null) {
          final rateSnapshot = <String, double>{
            'nitric': defaults.defaultNitricRate,
            'hcl': defaults.defaultHclRate,
            'worker': defaults.calculatedWorkerRate,
            'rent': defaults.calculatedRentRate,
            'account': defaults.calculatedAccountRate,
            'cu': defaults.defaultCuRate,
            'tin': defaults.defaultTinRate,
            'pd': defaults.defaultPdRate,
            'other': defaults.defaultOtherRate,
          };
          
          _lot = _lot.copyWith(rateSnapshot: rateSnapshot);
        }
        
        // For existing LOTs without snapshot, they should NOT get current defaults
        // They should continue using current defaults dynamically (legacy behavior)
        // Only new LOTs get rate snapshots to preserve their creation-time rates
        
        // Trigger initial calculation after engine is loaded
        _calculateResults();
      } else {
        // Create default defaults if none exist
        final defaultDefaults = ConfigurableDefaults(
          defaultNitricRate: 26.0,
          defaultHclRate: 1.7,
          defaultPdRate: 12000.0,
          defaultCuRate: 600.0,
          defaultTinRate: 38.0,
          defaultOtherRate: 4.0,
          workerFixedAmount: 38000.0,
          rentFixedAmount: 25000.0,
          accountFixedAmount: 5000.0,
          fixedDenominator: 4500.0,
          cuPercentage: 10.0,
          tinNumerator: 11.0,
          tinDenominator: 30.0,
        );
        
        // Save defaults for future use
        await MobileStorageService.saveDefaults(defaultDefaults);
        
        // Initialize with default defaults
        _calculationEngine = AdvancedCalculationEngine(defaultDefaults);
        
        // Create rate snapshot for new LOT
        if (_lot.rateSnapshot.isEmpty && widget.lot == null) {
          final rateSnapshot = <String, double>{
            'nitric': defaultDefaults.defaultNitricRate,
            'hcl': defaultDefaults.defaultHclRate,
            'worker': defaultDefaults.calculatedWorkerRate,
            'rent': defaultDefaults.calculatedRentRate,
            'account': defaultDefaults.calculatedAccountRate,
            'cu': defaultDefaults.defaultCuRate,
            'tin': defaultDefaults.defaultTinRate,
            'pd': defaultDefaults.defaultPdRate,
            'other': defaultDefaults.defaultOtherRate,
          };
          
          _lot = _lot.copyWith(rateSnapshot: rateSnapshot);
        }
        
        // For existing LOTs without snapshot, they should NOT get current defaults
        // They should continue using current defaults dynamically (legacy behavior)
        // Only new LOTs get rate snapshots to preserve their creation-time rates
        
        // Trigger initial calculation
        _calculateResults();
      }
    } catch (e) {
      print('Error initializing calculation engine: $e');
    }
  }

  @override
  void dispose() {
    _saveLotData(); // Auto-save data before disposing to prevent data loss
    _lotNumberController.dispose();
    _pattiQuantityController.dispose();
    _pattiRateController.dispose();
    _pdQuantityController.dispose();
    _notesController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Auto-save LOT data to prevent data loss on navigation
  void _saveLotData() {
    if (_lot.id.isNotEmpty) {
      final pattiQuantity = double.tryParse(_pattiQuantityController.text) ?? 0.0;
      final pattiRate = double.tryParse(_pattiRateController.text) ?? 0.0;
      final pdQuantity = double.tryParse(_pdQuantityController.text);
      final notes = _notesController.text.trim();
      
      final updatedLot = _lot.copyWith(
        lotNumber: _lotNumberController.text.trim(),
        pattiQuantity: pattiQuantity,
        pattiRate: pattiRate,
        pdQuantity: pdQuantity,
        manualEntries: _manualEntries,
        customRates: _customRates,
        calculationResult: _calculationResult,
        notes: notes.isEmpty ? null : notes,
        // Keep existing rateSnapshot - don't overwrite LOT's historical rates
      );
      
      // Save asynchronously but don't wait
      LotStorageService.saveLot(updatedLot).catchError((e) {
        print('Error auto-saving LOT: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lot != null ? 'LOT ${_lot.lotNumber}' : 'New LOT',
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: AppTheme.lightSystemUiOverlay,
        actions: [
          if (_lot.status == LotStatus.draft && widget.lot != null)
            TextButton(
              onPressed: _startLot,
              child: Text(
                'Start',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_lot.status == LotStatus.inProgress)
            TextButton(
              onPressed: _completeLot,
              child: Text(
                'Complete',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.successGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            onPressed: _saveLot,
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : Icon(
                    Icons.save,
                    color: AppColors.primaryBlue,
                  ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'LOT Data'),
            Tab(text: 'Materials'),
            Tab(text: 'Results'),
          ],
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryBlue,
        ),
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
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildLotDataTab(),
                  _buildMaterialsTab(),
                  _buildResultsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildLotDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLotInfo(),
            const SizedBox(height: AppTheme.spacing16),
            _buildPattiDetailsSection(),
            const SizedBox(height: AppTheme.spacing16),
            _buildPrimaryProductSection(),
            const SizedBox(height: AppTheme.spacing16),
            _buildNotesSection(),
            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCalculatedMaterialsSection(),
          const SizedBox(height: AppTheme.spacing16),
          _buildManualEntriesSection(),
          const SizedBox(height: AppTheme.spacing32),
        ],
      ),
    );
  }

  Widget _buildResultsTab() {
    if (_calculationResult == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assessment_outlined,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'Enter Patti quantity and rate to see results',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    final result = _calculationResult!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPnLSummary(result),
          const SizedBox(height: AppTheme.spacing16),
          _buildCostBreakdown(result),
          const SizedBox(height: AppTheme.spacing16),
          _buildEfficiencyMetrics(result),
          const SizedBox(height: AppTheme.spacing32),
        ],
      ),
    );
  }

  Widget _buildLotInfo() {
    final dateFormat = DateFormat('MMM d, y');
    
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LOT Information',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildStatusChip(_lot.status),
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
                        'LOT Number',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _lotNumberController,
                          style: AppTheme.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacing8,
                              vertical: AppTheme.spacing4,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
                              borderSide: BorderSide(color: AppColors.primaryBlue),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'LOT number required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Started',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        dateFormat.format(_lot.startDate),
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_lot.completedDate != null) ...[
              const SizedBox(height: AppTheme.spacing12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completed',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          dateFormat.format(_lot.completedDate!),
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.successGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duration',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${_lot.durationInDays} days',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            // Add delete button for draft LOTs
            if (widget.lot != null) ...[
              const SizedBox(height: AppTheme.spacing16),
              const Divider(),
              const SizedBox(height: AppTheme.spacing12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _deleteLot,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.error,
                  ),
                  label: Text(
                    'Delete LOT',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacing8,
                    ),
                  ),
                ),
              ),
            ],
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
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppTheme.spacing4),
          Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPattiDetailsSection() {
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patti Details',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pattiQuantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Patti Quantity (kg)',
                      hintText: '0.0',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter patti quantity';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                    onChanged: (value) => _calculateResults(),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: TextFormField(
                    controller: _pattiRateController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Patti Rate (₹/kg)',
                      hintText: '0.0',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter patti rate';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                    onChanged: (value) => _calculateResults(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryProductSection() {
    final pdQuantity = double.tryParse(_pdQuantityController.text) ?? 0.0;
    final pattiQuantity = double.tryParse(_pattiQuantityController.text) ?? 0.0;
    final pdEfficiency = pattiQuantity > 0 && pdQuantity > 0 ? (pdQuantity / pattiQuantity) * 100 : 0.0;
    
    // Get PD Profit for color coding
    Color efficiencyColor = AppColors.textSecondary;
    if (_calculationResult != null) {
      final pdProfit = _calculationResult!.pnl;
      if (pdProfit <= -1000) {
        efficiencyColor = AppColors.error; // Red
      } else if (pdProfit < 0) {
        efficiencyColor = AppColors.warning; // Yellow
      } else {
        efficiencyColor = AppColors.successGreen; // Green
      }
    }

    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Primary Product',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextFormField(
              controller: _pdQuantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                labelText: 'PD Quantity (kg)',
                hintText: 'Auto-calculated if left empty',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
              onChanged: (value) => _calculateResults(),
            ),
            if (pdQuantity > 0 && pattiQuantity > 0) ...[
              const SizedBox(height: AppTheme.spacing12),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: efficiencyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  border: Border.all(
                    color: efficiencyColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: efficiencyColor,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      'PD Efficiency: ',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${pdEfficiency.toStringAsFixed(4)}%',
                      style: AppTheme.bodyMedium.copyWith(
                        color: efficiencyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_calculationResult != null)
                      Text(
                        'P&L: ₹${_calculationResult!.pnl.toStringAsFixed(0)}',
                        style: AppTheme.bodySmall.copyWith(
                          color: efficiencyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntriesSection() {
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Materials & Costs',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addManualEntry,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Entry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing12,
                      vertical: AppTheme.spacing6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            if (_manualEntries.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        'No materials added yet',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        'Add materials and costs to track expenses',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _manualEntries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final material = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                    child: _buildManualEntryCard(material, index),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryCard(Map<String, dynamic> entry, int index) {
    final name = entry['name'] ?? 'Unknown';
    final quantity = entry['quantity']?.toDouble() ?? 0.0;
    final rate = entry['rate']?.toDouble() ?? 0.0;
    final total = quantity * rate;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  '${quantity.toStringAsFixed(1)} kg × ₹${rate.toStringAsFixed(0)} = ₹${total.toStringAsFixed(0)}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'edit') {
                _editManualEntry(index);
              } else if (action == 'delete') {
                _deleteManualEntry(index);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: AppColors.primaryBlue),
                    const SizedBox(width: AppTheme.spacing8),
                    const Text('Edit'),
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
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationResults() {
    if (_calculationResult == null) {
      return PremiumCard(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'No calculations yet',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  'Add patti details and materials to see results',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculation Results',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              children: [
                Expanded(
                  child: _buildResultCard(
                    'P&L',
                    '₹${_calculationResult!.finalProfitLoss.toStringAsFixed(0)}',
                    _calculationResult!.finalProfitLoss >= 0 
                        ? AppColors.successGreen 
                        : AppColors.error,
                    Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: _buildResultCard(
                    'Efficiency',
                    '${_calculationResult!.pdEfficiency.toStringAsFixed(1)}%',
                    AppColors.primaryBlue,
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            Row(
              children: [
                Expanded(
                  child: _buildResultCard(
                    'Revenue',
                    '₹${(_calculationResult!.pdIncome + _calculationResult!.netByproductIncome).toStringAsFixed(0)}',
                    AppColors.successGreen,
                    Icons.attach_money,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: _buildResultCard(
                    'Cost',
                    '₹${_calculationResult!.phase1TotalCost.toStringAsFixed(0)}',
                    AppColors.warning,
                    Icons.money_off,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppTheme.spacing4),
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            value,
            style: AppTheme.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: AppTheme.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any notes about this LOT...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addManualEntry() {
    showDialog(
      context: context,
      builder: (context) => _ManualEntryDialog(
        onSave: (entry) async {
          setState(() {
            _manualEntries.add(entry);
            _calculateResults();
          });
          
          // Auto-save the LOT with updated manual entries
          await _saveManualEntries();
        },
      ),
    );
  }

  void _editManualEntry(int index) {
    showDialog(
      context: context,
      builder: (context) => _ManualEntryDialog(
        entry: _manualEntries[index],
        onSave: (entry) async {
          setState(() {
            _manualEntries[index] = entry;
            _calculateResults();
          });
          
          // Auto-save the LOT with updated manual entries
          await _saveManualEntries();
        },
      ),
    );
  }

  void _deleteManualEntry(int index) async {
    setState(() {
      _manualEntries.removeAt(index);
      _calculateResults();
    });
    
    // Auto-save the LOT with updated manual entries
    await _saveManualEntries();
  }

  Map<String, double> _getEffectiveRates() {
    final effectiveRates = <String, double>{};

    // Different behavior for new LOTs vs existing LOTs
    if (_lot.rateSnapshot.isNotEmpty) {
      // LOT has rate snapshot (new LOT created after rate snapshot feature)
      // Use snapshot rates (preserves creation-time rates)
      effectiveRates.addAll(_lot.rateSnapshot);
    } else if (widget.lot != null) {
      // Existing LOT without snapshot (legacy LOT)
      // IMPORTANT: For true rate independence, these LOTs should freeze their rates
      // at the time they were last calculated. Since we don't have that data,
      // we need to create a snapshot from CURRENT defaults and save it.
      if (_calculationEngine != null) {
        final defaults = _calculationEngine!.defaults;
        final frozenRates = <String, double>{
          'nitric': defaults.defaultNitricRate,
          'hcl': defaults.defaultHclRate,
          'worker': defaults.calculatedWorkerRate,
          'rent': defaults.calculatedRentRate,
          'account': defaults.calculatedAccountRate,
          'cu': defaults.defaultCuRate,
          'tin': defaults.defaultTinRate,
          'pd': defaults.defaultPdRate,
          'other': defaults.defaultOtherRate,
        };
        effectiveRates.addAll(frozenRates);
        
        // Save this as the LOT's permanent rate snapshot
        _lot = _lot.copyWith(rateSnapshot: frozenRates);
        
        // Save immediately to prevent future changes
        LotStorageService.saveLot(_lot).catchError((e) {
          print('Error saving rate freeze: $e');
        });
      }
    } else {
      // New LOT (should already have rate snapshot from initialization)
      // Use current defaults as fallback
      if (_calculationEngine != null) {
        final defaults = _calculationEngine!.defaults;
        effectiveRates.addAll({
          'nitric': defaults.defaultNitricRate,
          'hcl': defaults.defaultHclRate,
          'worker': defaults.calculatedWorkerRate,
          'rent': defaults.calculatedRentRate,
          'account': defaults.calculatedAccountRate,
          'cu': defaults.defaultCuRate,
          'tin': defaults.defaultTinRate,
          'pd': defaults.defaultPdRate,
          'other': defaults.defaultOtherRate,
        });
      }
    }

    // Finally override with custom rates (LOT-specific changes)
    effectiveRates.addAll(_customRates);
    
    return effectiveRates;
  }

  Future<void> _saveManualEntries() async {
    try {
      final pattiQuantity = double.tryParse(_pattiQuantityController.text) ?? 0.0;
      final pattiRate = double.tryParse(_pattiRateController.text) ?? 0.0;
      final pdQuantity = double.tryParse(_pdQuantityController.text);
      final notes = _notesController.text.trim();
      
      final updatedLot = _lot.copyWith(
        lotNumber: _lotNumberController.text.trim(),
        pattiQuantity: pattiQuantity,
        pattiRate: pattiRate,
        pdQuantity: pdQuantity,
        manualEntries: _manualEntries,
        customRates: _customRates,
        calculationResult: _calculationResult,
        notes: notes.isEmpty ? null : notes,
      );
      
      await LotStorageService.saveLot(updatedLot);
      
      setState(() {
        _lot = updatedLot;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Manual entries saved successfully!'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving manual entries: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving manual entries: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _calculateResults() {
    try {
      final pattiQuantity = double.tryParse(_pattiQuantityController.text) ?? 0.0;
      final pattiRate = double.tryParse(_pattiRateController.text) ?? 0.0;
      final pdQuantity = double.tryParse(_pdQuantityController.text);


      if (pattiQuantity > 0 && pattiRate > 0 && _calculationEngine != null) {
        // Calculate manual entries totals
        double manualIncome = 0.0;
        double manualExpenses = 0.0;
        
        for (final entry in _manualEntries) {
          final quantity = entry['quantity']?.toDouble() ?? 0.0;
          final rate = entry['rate']?.toDouble() ?? 0.0;
          final amount = quantity * rate;
          final isIncome = entry['type'] == 'income';
          
          if (isIncome) {
            manualIncome += amount;
          } else {
            manualExpenses += amount;
          }
        }

        // Use the same effective rates logic as Materials tab
        final effectiveRates = _getEffectiveRates();
        
        // Use AdvancedCalculationEngine for automatic calculation of HCl, nitric, etc.
        final result = _calculationEngine!.calculateProcess(
          pattiQuantity: pattiQuantity,
          pattiRate: pattiRate,
          pdQuantity: pdQuantity,
          customRates: effectiveRates,
          manualIncome: manualIncome,
          manualExpenses: manualExpenses,
        );
        
        setState(() {
          _calculationResult = result;
        });
      } else {
        setState(() {
          _calculationResult = null;
        });
      }
    } catch (e) {
      print('Error calculating results: $e');
      setState(() {
        _calculationResult = null;
      });
    }
  }

  Future<void> _saveLot() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final lotNumber = _lotNumberController.text.trim();
      final pattiQuantity = double.tryParse(_pattiQuantityController.text) ?? 0.0;
      final pattiRate = double.tryParse(_pattiRateController.text) ?? 0.0;
      final pdQuantity = double.tryParse(_pdQuantityController.text);
      final notes = _notesController.text.trim();

      final updatedLot = _lot.copyWith(
        lotNumber: lotNumber,
        pattiQuantity: pattiQuantity,
        pattiRate: pattiRate,
        pdQuantity: pdQuantity,
        manualEntries: _manualEntries,
        customRates: _customRates,
        calculationResult: _calculationResult,
        notes: notes.isEmpty ? null : notes,
        // Keep existing rateSnapshot - preserve LOT's historical rates
      );

      await LotStorageService.saveLot(updatedLot);
      await CloudStorageService.saveLot(updatedLot);

      setState(() {
        _lot = updatedLot;
      });

      // Always show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('LOT ${_lot.lotNumber} saved successfully!'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving LOT: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _startLot() async {
    try {
      final startedLot = await LotStorageService.markLotAsInProgress(_lot.id);
      setState(() {
        _lot = startedLot;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('LOT ${_lot.lotNumber} started successfully!'),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting LOT: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _completeLot() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete LOT'),
        content: Text('Are you sure you want to complete LOT ${_lot.lotNumber}? This will mark it as completed with today\'s date.'),
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
        final completedLot = await LotStorageService.completeLot(_lot.id);
        setState(() {
          _lot = completedLot;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('LOT ${_lot.lotNumber} completed successfully!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error completing LOT: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildCalculatedMaterialsSection() {
    if (_calculationEngine == null) {
      return const SizedBox.shrink();
    }

    final pattiQuantity = double.tryParse(_pattiQuantityController.text) ?? 0.0;
    final pattiRate = double.tryParse(_pattiRateController.text) ?? 0.0;
    
    if (pattiQuantity <= 0 || pattiRate <= 0) {
      return Column(
        children: [
          PremiumCard(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                children: [
                  Icon(
                    Icons.science_outlined,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    'Auto-calculated Materials',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    'Enter Patti quantity and rate to see calculated materials',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          PremiumCard(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_outlined,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    'ByProduct Materials',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    'CU and TIN byproducts will appear here',
                    textAlign: TextAlign.center,
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

    // Use the same effective rates logic as _calculateResults
    final effectiveRates = _getEffectiveRates();
    
    final materials = _calculationEngine!.createMaterialInputs(
      pattiQuantity: pattiQuantity,
      pattiRate: pattiRate,
      customRates: effectiveRates,
    );

    // Separate materials into main and byproduct
    final mainMaterials = materials.where((m) => m.category != MaterialCategory.byproduct).toList();
    final byproductMaterials = materials.where((m) => m.category == MaterialCategory.byproduct).toList();

    return Column(
      children: [
        // Main Materials Section
        PremiumCard(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-calculated Materials',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing16),
                ...mainMaterials.map((material) => _buildEditableMaterialDisplay(material)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        // ByProduct Materials Section
        if (byproductMaterials.isNotEmpty)
          PremiumCard(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_outlined,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        'ByProduct Materials',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  ...byproductMaterials.map((material) => _buildEditableMaterialDisplay(material)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEditableMaterialDisplay(MaterialInput material) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.name,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${material.quantity.toStringAsFixed(2)} kg',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => _editMaterialRate(material),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing6,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: material.isDefaultRate 
                      ? AppColors.primaryBlue.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${material.rate.toStringAsFixed(2)}',
                      style: AppTheme.bodySmall.copyWith(
                        color: material.isDefaultRate ? AppColors.primaryBlue : AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Icon(
                      Icons.edit,
                      size: 10,
                      color: material.isDefaultRate ? AppColors.primaryBlue : AppColors.warning,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '₹${material.amount.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: AppTheme.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPnLSummary(CalculationResult result) {
    return PremiumCard(
      child: Container(
        decoration: BoxDecoration(
          color: result.isProfitNegative 
              ? AppColors.error.withValues(alpha: 0.1)
              : AppColors.successGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        ),
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
                      color: result.isProfitNegative 
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                    ),
                    child: Icon(
                      result.isProfitNegative ? Icons.trending_down : Icons.trending_up,
                      color: result.isProfitNegative ? AppColors.error : AppColors.successGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Text(
                    'Net P&L Summary',
                    style: AppTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              _buildPnLRow('Net Profit', result.netProfit, isTotal: true, isNegative: result.isProfitNegative),
              _buildPnLRow('Gross Profit', result.grossProfit),
              _buildPnLRow('Total Cost', result.phase1TotalCost),
              _buildPnLRow('PD Income', result.pdIncome),
              if (result.cuIncome > 0 || result.tinCost > 0) ...[
                _buildPnLRow('CU Income', result.cuIncome),
                _buildPnLRow('TIN Cost', -result.tinCost),
                _buildPnLRow('Byproduct Net', result.cuIncome - result.tinCost),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostBreakdown(CalculationResult result) {
    final pdQuantity = double.tryParse(_pdQuantityController.text) ?? 0.0;
    
    return PremiumCard(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius12),
        ),
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
                      Icons.calculate_outlined,
                      color: AppColors.info,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Text(
                    'Cost Breakdown Analysis',
                    style: AppTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              _buildCostBreakdownRow('Phase 1 Total Cost', result.phase1WithOther),
              _buildCostBreakdownRow('TIN Expenses', result.tinCost, isExpense: true),
              _buildCostBreakdownRow('PD Profit', result.pnl, isIncome: true),
              _buildCostBreakdownRow('CU Income', result.cuIncome, isIncome: true),
              const Divider(height: AppTheme.spacing24),
              _buildCostBreakdownRow('Total Cost', result.totalCost, isTotal: true),
              _buildCostBreakdownRow('PD Quantity', pdQuantity, unit: 'kg', precision: 3),
              const Divider(height: AppTheme.spacing24),
              _buildCostBreakdownRow('Cost per 1 KG PD', result.costPer1kgPd, isResult: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEfficiencyMetrics(CalculationResult result) {
    return PremiumCard(
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
                    Icons.trending_up,
                    color: AppColors.info,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Text(
                  'Efficiency Metrics',
                  style: AppTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            _buildMetricsRow('PD Efficiency', '${result.pdEfficiency.toStringAsFixed(4)}%'),
            _buildMetricsRow('Profit per 100kg', '₹${result.profitPer100kg.toStringAsFixed(2)}'),
            _buildMetricsRow('Material Cost/Unit', '₹${result.materialCostPerUnit.toStringAsFixed(2)}'),
            _buildMetricsRow('Chemical Cost/Unit', '₹${result.chemicalCostPerUnit.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPnLRow(String label, double value, {bool isTotal = false, bool isNegative = false, bool isManual = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: AppTheme.bodyMedium.copyWith(
              color: isTotal 
                  ? (isNegative ? AppColors.error : AppColors.successGreen)
                  : AppColors.textPrimary,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostBreakdownRow(String label, double value, {bool isTotal = false, bool isExpense = false, bool isIncome = false, bool isResult = false, String unit = '₹', int precision = 2}) {
    Color textColor = AppColors.textPrimary;
    if (isResult) textColor = AppColors.primaryBlue;
    if (isIncome) textColor = AppColors.successGreen;
    if (isExpense) textColor = AppColors.error;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: isTotal || isResult ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            unit == '₹' ? '₹${value.toStringAsFixed(precision)}' : '${value.toStringAsFixed(precision)} $unit',
            style: AppTheme.bodyMedium.copyWith(
              color: textColor,
              fontWeight: isTotal || isResult ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
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
            value,
            style: AppTheme.bodyMedium.copyWith(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _editMaterialRate(MaterialInput material) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: material.rate.toStringAsFixed(2));
        return AlertDialog(
          title: Text('Edit ${material.name} Rate'),
          content: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Rate (₹/kg)',
              hintText: 'Enter new rate',
              prefixText: '₹',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newRate = double.tryParse(controller.text);
                if (newRate != null && newRate > 0) {
                  setState(() {
                    _customRates[material.materialId] = newRate;
                  });
                  _calculateResults();
                  
                  // Auto-save the LOT with updated custom rates
                  try {
                    final updatedLot = _lot.copyWith(
                      customRates: _customRates,
                      calculationResult: _calculationResult,
                    );
                    await LotStorageService.saveLot(updatedLot);
                    setState(() {
                      _lot = updatedLot;
                    });
                    
                    Navigator.pop(context);
                    
                    // Show success message
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${material.name} rate updated to ₹${newRate.toStringAsFixed(2)}'),
                          backgroundColor: AppColors.successGreen,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error saving rate: $e'),
                          backgroundColor: AppColors.error,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLot() async {
    // Different confirmation messages based on LOT status
    String title;
    String content;
    
    switch (_lot.status) {
      case LotStatus.draft:
        title = 'Delete Draft LOT';
        content = 'Are you sure you want to delete LOT ${_lot.lotNumber}? This action cannot be undone.';
        break;
      case LotStatus.inProgress:
        title = 'Delete In-Progress LOT';
        content = 'WARNING: LOT ${_lot.lotNumber} is currently in progress. Deleting it will permanently remove all production data. Are you sure you want to continue?';
        break;
      case LotStatus.completed:
        title = 'Delete Completed LOT';
        content = 'CAUTION: LOT ${_lot.lotNumber} is completed with financial data. Deleting it will permanently remove all production and financial records. Are you sure you want to continue?';
        break;
      default:
        title = 'Delete LOT';
        content = 'Are you sure you want to delete LOT ${_lot.lotNumber}? This action cannot be undone.';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
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
        await LotStorageService.deleteLot(_lot.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('LOT ${_lot.lotNumber} deleted successfully!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          Navigator.pop(context); // Go back to LOT management
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting LOT: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

class _ManualEntryDialog extends StatefulWidget {
  final Map<String, dynamic>? entry;
  final Function(Map<String, dynamic>) onSave;

  const _ManualEntryDialog({
    this.entry,
    required this.onSave,
  });

  @override
  State<_ManualEntryDialog> createState() => _ManualEntryDialogState();
}

class _ManualEntryDialogState extends State<_ManualEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _nameController.text = widget.entry!['name'] ?? '';
      _quantityController.text = widget.entry!['quantity']?.toString() ?? '';
      _rateController.text = widget.entry!['rate']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.entry != null ? 'Edit Material' : 'Add Material'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Material Name',
                hintText: 'e.g., Copper, Tin, Labor',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter material name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacing12),
            TextFormField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: '0.0',
                suffixText: 'kg',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppTheme.spacing12),
            TextFormField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Rate',
                hintText: '0.0',
                prefixText: '₹',
                suffixText: '/kg',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter rate';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final entry = {
        'name': _nameController.text.trim(),
        'quantity': double.parse(_quantityController.text),
        'rate': double.parse(_rateController.text),
      };
      
      widget.onSave(entry);
      Navigator.pop(context);
    }
  }
}