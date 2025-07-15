import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/platform_storage_service.dart';
import '../services/calculation_engine.dart';
import '../models/configurable_defaults.dart';
import '../models/production_batch.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_card.dart';

class MobileBatchEntryScreen extends StatefulWidget {
  final DateTime date;
  
  const MobileBatchEntryScreen({super.key, required this.date});

  @override
  State<MobileBatchEntryScreen> createState() => _MobileBatchEntryScreenState();
}

class _MobileBatchEntryScreenState extends State<MobileBatchEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _pattiQuantityController = TextEditingController();
  final _pattiRateController = TextEditingController();
  final _pdQuantityController = TextEditingController();
  
  ConfigurableDefaults? _defaults;
  AdvancedCalculationEngine? _calculationEngine;
  CalculationResult? _currentResult;
  List<String> _validationErrors = [];
  
  double _pattiQuantity = 0;
  double _pattiRate = 0;
  double? _pdQuantity;
  Map<String, double> _customRates = {};
  List<Map<String, dynamic>> _manualEntries = [];
  
  bool _isLoading = true;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.date;
    _tabController = TabController(length: 3, vsync: this);
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    try {
      final defaults = await PlatformStorageService.getDefaults();
      setState(() {
        _defaults = defaults ?? ConfigurableDefaults.createDefault();
        _calculationEngine = AdvancedCalculationEngine(_defaults!);
      });
      
      // Try to load existing batch data
      await _loadExistingBatch();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading defaults: $e')),
      );
    }
  }
  
  Future<void> _loadExistingBatch() async {
    try {
      final existingBatch = await PlatformStorageService.getBatchByDate(_selectedDate);
      if (existingBatch != null) {
        setState(() {
          _pattiQuantity = existingBatch.pattiQuantity;
          _pattiRate = existingBatch.pattiRate;
          _pdQuantity = existingBatch.pdQuantity;
          _customRates = Map<String, double>.from(existingBatch.customRates ?? {});
          _manualEntries = List<Map<String, dynamic>>.from(existingBatch.manualEntries ?? []);
          
          // Update controllers
          if (_pattiQuantity > 0) {
            _pattiQuantityController.text = _pattiQuantity.toString();
          }
          if (_pattiRate > 0) {
            _pattiRateController.text = _pattiRate.toString();
          }
          if (_pdQuantity != null && _pdQuantity! > 0) {
            _pdQuantityController.text = _pdQuantity.toString();
          }
        });
        
        _recalculate();
      }
    } catch (e) {
      print('Error loading existing batch: $e');
    }
  }

  void _recalculate() {
    if (_calculationEngine == null) return;

    // Calculate manual entries total
    double manualIncomeTotal = 0;
    double manualExpenseTotal = 0;
    for (final entry in _manualEntries) {
      if (entry['type'] == 'income') {
        manualIncomeTotal += entry['amount'] ?? 0;
      } else {
        manualExpenseTotal += entry['amount'] ?? 0;
      }
    }

    // Calculate results
    final result = _calculationEngine!.calculateProcess(
      pattiQuantity: _pattiQuantity,
      pattiRate: _pattiRate,
      pdQuantity: _pdQuantity,
      customRates: _customRates,
      manualIncome: manualIncomeTotal,
      manualExpenses: manualExpenseTotal,
    );

    setState(() {
      _currentResult = result;
    });
  }

  Future<void> _saveBatch() async {
    if (_defaults == null || _currentResult == null) return;

    try {
      final batch = ProductionBatch(
        date: _selectedDate,
        pattiQuantity: _pattiQuantity,
        pattiRate: _pattiRate,
        pdQuantity: _pdQuantity,
        customRates: _customRates,
        manualEntries: _manualEntries,
        calculationResult: _currentResult,
        createdAt: DateTime.now(),
      );

      await PlatformStorageService.saveBatch(batch);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batch saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving batch: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pattiQuantityController.dispose();
    _pattiRateController.dispose();
    _pdQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, y');

    if (_isLoading) {
      return Scaffold(
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppColors.primaryBlue,
                  strokeWidth: 3,
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  'Loading Batch Entry...',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Batch Entry',
              style: AppTheme.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: _showDatePicker,
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  Text(
                    dateFormat.format(_selectedDate),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  Icon(
                    Icons.edit,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showDatePicker,
            icon: Icon(
              Icons.calendar_month,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Change Date',
          ),
          ElevatedButton.icon(
            onPressed: _saveBatch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: Colors.white,
              elevation: 2,
            ),
            icon: const Icon(Icons.save, size: 20),
            label: const Text('Save'),
          ),
          const SizedBox(width: AppTheme.spacing16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 3,
          labelStyle: AppTheme.labelMedium,
          unselectedLabelStyle: AppTheme.bodySmall,
          tabs: [
            Tab(
              text: 'Raw Materials',
              icon: Icon(Icons.inventory_2, color: AppColors.rawMaterial, size: 20),
            ),
            Tab(
              text: 'Production', 
              icon: Icon(Icons.precision_manufacturing, color: AppColors.product, size: 20),
            ),
            Tab(
              text: 'Results',
              icon: Icon(Icons.assessment, color: AppColors.info, size: 20),
            ),
          ],
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
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildRawMaterialsTab(),
            _buildProductionTab(),
            _buildResultsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRawMaterialsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Base Material Input
          PremiumCard(
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
                          color: AppColors.rawMaterial.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.rawMaterial,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing12),
                      Text(
                        'Base Material (Patti)',
                        style: AppTheme.headlineSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    controller: _pattiQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'Patti Quantity (kg)',
                      hintText: 'Enter quantity',
                      prefixIcon: Icon(Icons.scale),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _pattiQuantity = double.tryParse(value) ?? 0;
                      _recalculate();
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    controller: _pattiRateController,
                    decoration: const InputDecoration(
                      labelText: 'Patti Rate (₹/kg)',
                      hintText: 'Enter rate',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _pattiRate = double.tryParse(value) ?? 0;
                      _recalculate();
                    },
                  ),
                  if (_pattiQuantity > 0 && _pattiRate > 0) ...[
                    const SizedBox(height: AppTheme.spacing12),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount:',
                            style: AppTheme.titleMedium,
                          ),
                          Text(
                            '₹${(_pattiQuantity * _pattiRate).toStringAsFixed(2)}',
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Derived Materials
          if (_pattiQuantity > 0 && _defaults != null) ...[
            const SizedBox(height: AppTheme.spacing16),
            PremiumCard(
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
                            color: AppColors.derivedMaterial.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                          ),
                          child: Icon(
                            Icons.science_outlined,
                            color: AppColors.derivedMaterial,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        Text(
                          'Derived Materials',
                          style: AppTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildEditableMaterialDisplay('Nitric', _pattiQuantity * 1.4, _defaults!.defaultNitricRate, 'nitric'),
                    _buildEditableMaterialDisplay('HCL', _pattiQuantity * 1.4 * 3.0, _defaults!.defaultHclRate, 'hcl'),
                    _buildEditableMaterialDisplay('Worker', _pattiQuantity, _defaults!.calculatedWorkerRate, 'worker'),
                    _buildEditableMaterialDisplay('Rent', _pattiQuantity, _defaults!.calculatedRentRate, 'rent'),
                    _buildEditableMaterialDisplay('Account', _pattiQuantity, _defaults!.calculatedAccountRate, 'account'),
                  ],
                ),
              ),
            ),
          ],

          // Byproduct Materials
          if (_pattiQuantity > 0 && _defaults != null) ...[
            const SizedBox(height: AppTheme.spacing16),
            PremiumCard(
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
                            color: AppColors.byproduct.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                          ),
                          child: Icon(
                            Icons.recycling_outlined,
                            color: AppColors.byproduct,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        Text(
                          'Byproduct Materials',
                          style: AppTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    _buildEditableMaterialDisplay('CU', _pattiQuantity * (_defaults!.cuPercentage / 100), _defaults!.defaultCuRate, 'cu'),
                    _buildEditableMaterialDisplay('TIN', _pattiQuantity * (_defaults!.tinNumerator / _defaults!.tinDenominator), _defaults!.defaultTinRate, 'tin'),
                  ],
                ),
              ),
            ),
          ],

          // Manual Income/Expense Entries
          const SizedBox(height: AppTheme.spacing16),
          PremiumCard(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              Icons.edit_note_outlined,
                              color: AppColors.info,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing12),
                          Text(
                            'Manual Entries',
                            style: AppTheme.headlineSmall,
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _addManualEntry,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing12,
                            vertical: AppTheme.spacing8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  if (_manualEntries.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Expanded(
                            child: Text(
                              'No manual entries added. Use "Add" to include custom income or expenses.',
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._manualEntries.asMap().entries.map((entry) => 
                      _buildManualEntryRow(entry.key, entry.value)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primary Product',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pdQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'PD Quantity (kg)',
                      hintText: 'Enter quantity',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _pdQuantity = double.tryParse(value);
                      _recalculate();
                    },
                  ),
                  if (_pdQuantity != null && _pdQuantity! > 0 && _pattiQuantity > 0) ...[
                    const SizedBox(height: 16),
                    _buildEfficiencyCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTab() {
    if (_currentResult == null) {
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
    final result = _currentResult!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // P&L Summary
          PremiumCard(
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
                  if (_manualEntries.isNotEmpty) ...[
                    const Divider(height: AppTheme.spacing24),
                    ..._manualEntries.map((entry) => _buildPnLRow(
                      entry['description'],
                      entry['type'] == 'income' ? entry['amount'] : -entry['amount'],
                      isManual: true,
                    )),
                  ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),

          // Cost Breakdown (Excel Formula)
          if (_pdQuantity != null && _pdQuantity! > 0) ...[
            PremiumCard(
              child: Container(
                decoration: BoxDecoration(
                  color: _getCostBreakdownColor(result),
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
                    _buildCostBreakdownRow('PD Quantity', _pdQuantity ?? 0, unit: 'kg'),
                    const Divider(height: AppTheme.spacing24),
                    _buildCostBreakdownRow('Cost per 1 KG PD', result.costPer1kgPd, isResult: true),
                  ],
                ),
              ),
            ),
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
          
          // Efficiency Metrics
          PremiumCard(
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
                  _buildMetricRow('PD Efficiency', '${result.pdEfficiency.toStringAsFixed(3)}%', 
                    isValid: result.pdEfficiency >= 0.1 && result.pdEfficiency <= 10.0),
                  _buildMetricRow('Profit per 100kg', '₹${result.profitPer100kg.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard() {
    final efficiency = (_pdQuantity! / _pattiQuantity) * 100;
    final isValid = efficiency >= 0.1 && efficiency <= 10.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isValid ? Colors.green.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.warning,
            color: isValid ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(
            'PD Efficiency: ${efficiency.toStringAsFixed(3)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isValid ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPnLRow(String label, double amount, {bool isTotal = false, bool isNegative = false, bool isManual = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 16 : 14,
                ),
              ),
              if (isManual) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.edit,
                  size: 12,
                  color: Colors.grey[600],
                ),
              ],
            ],
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 16 : 14,
              color: isNegative ? Colors.red : (amount >= 0 ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableMaterialDisplay(String name, double quantity, double defaultRate, String rateKey) {
    final currentRate = _customRates[rateKey] ?? defaultRate;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Material name and quantity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: AppTheme.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${quantity.toStringAsFixed(2)} kg',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          // Rate input and total
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate (₹/kg)',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextFormField(
                        initialValue: currentRate.toStringAsFixed(2),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing12, 
                            vertical: AppTheme.spacing8
                          ),
                          border: InputBorder.none,
                          hintText: 'Enter rate',
                          hintStyle: AppTheme.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final newRate = double.tryParse(value);
                          if (newRate != null) {
                            setState(() {
                              _customRates[rateKey] = newRate;
                            });
                            _recalculate();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12,
                        vertical: AppTheme.spacing8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          '₹${(quantity * currentRate).toStringAsFixed(2)}',
                          style: AppTheme.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryRow(int index, Map<String, dynamic> entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: entry['type'] == 'income' 
              ? AppColors.successGreen.withValues(alpha: 0.1)
              : AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
          border: Border.all(
            color: entry['type'] == 'income' 
                ? AppColors.successGreen.withValues(alpha: 0.3)
                : AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              entry['type'] == 'income' ? Icons.add_circle : Icons.remove_circle,
              color: entry['type'] == 'income' ? AppColors.successGreen : AppColors.error,
              size: 20,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              flex: 2,
              child: Text(
                entry['description'] ?? 'Manual Entry',
                style: AppTheme.labelMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                entry['type'] == 'income' ? 'Income' : 'Expense',
                style: AppTheme.bodySmall.copyWith(
                  color: entry['type'] == 'income' ? AppColors.successGreen : AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Text(
                '₹${entry['amount']?.toStringAsFixed(2) ?? '0.00'}',
                style: AppTheme.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: entry['type'] == 'income' ? AppColors.successGreen : AppColors.error,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              onPressed: () => _removeManualEntry(index),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  void _addManualEntry() {
    showDialog(
      context: context,
      builder: (context) {
        String description = '';
        double amount = 0;
        String type = 'expense';
        
        return AlertDialog(
          title: Text(
            'Add Manual Entry',
            style: AppTheme.titleMedium,
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g., Transport, Maintenance',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    onChanged: (value) => description = value,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      hintText: 'Enter amount',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => amount = double.tryParse(value) ?? 0,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'expense', child: Text('Expense')),
                      DropdownMenuItem(value: 'income', child: Text('Income')),
                    ],
                    onChanged: (value) => setState(() => type = value ?? 'expense'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTheme.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (description.isNotEmpty && amount > 0) {
                  setState(() {
                    _manualEntries.add({
                      'description': description,
                      'amount': amount,
                      'type': type,
                    });
                  });
                  _recalculate();
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _removeManualEntry(int index) {
    setState(() {
      _manualEntries.removeAt(index);
    });
    _recalculate();
  }

  Color? _getCostBreakdownColor(CalculationResult result) {
    if (_pdQuantity == null || _pdQuantity! <= 0) return null;
    
    // Color coding based on Total Cost vs PD Income ratio
    final ratio = result.totalCost / result.pdIncome;
    
    if (ratio < 0.8) return AppColors.successGreen.withValues(alpha: 0.1); // Good - Total Cost < 80% of PD Income
    if (ratio < 0.95) return AppColors.warning.withValues(alpha: 0.1); // Warning - 80-95%
    return AppColors.error.withValues(alpha: 0.1); // Alert - > 95%
  }
  
  Widget _buildCostBreakdownRow(String label, double amount, {
    bool isTotal = false, 
    bool isResult = false, 
    bool isExpense = false, 
    bool isIncome = false,
    String unit = '',
  }) {
    String valueText;
    if (unit == 'kg') {
      valueText = '${amount.toStringAsFixed(3)} $unit';
    } else {
      String prefix = '';
      if (isExpense) prefix = '+';
      if (isIncome) prefix = '-';
      valueText = '$prefix₹${amount.toStringAsFixed(2)}';
    }
    
    Color? textColor;
    if (isIncome) textColor = AppColors.successGreen;
    if (isExpense) textColor = AppColors.error;
    if (isResult) textColor = AppColors.primaryBlue;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: isTotal || isResult ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal || isResult ? 16 : 14,
            ),
          ),
          Text(
            valueText,
            style: AppTheme.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isTotal || isResult ? 16 : 14,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isValid = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyMedium,
          ),
          Row(
            children: [
              if (!isValid) ...[
                Icon(
                  Icons.warning_outlined, 
                  color: AppColors.warning, 
                  size: 16
                ),
                const SizedBox(width: AppTheme.spacing4),
              ],
              Text(
                value,
                style: AppTheme.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isValid ? AppColors.primaryBlue : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDatePicker() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select batch date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );
    
    if (selectedDate != null && selectedDate != _selectedDate) {
      setState(() {
        _selectedDate = selectedDate;
      });
      // Reload data for the new date
      await _loadExistingBatch();
    }
  }
}