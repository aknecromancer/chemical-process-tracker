import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../services/web_storage_service.dart';
import '../services/calculation_engine.dart';
import '../models/configurable_defaults.dart';
import '../models/production_batch.dart';
import '../theme/app_theme.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_card.dart';

class WebBatchEntryScreen extends StatefulWidget {
  final DateTime date;
  
  const WebBatchEntryScreen({super.key, required this.date});

  @override
  State<WebBatchEntryScreen> createState() => _WebBatchEntryScreenState();
}

class _WebBatchEntryScreenState extends State<WebBatchEntryScreen>
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    try {
      final defaults = await WebStorageService.getDefaults();
      setState(() {
        _defaults = defaults;
        _calculationEngine = AdvancedCalculationEngine(defaults);
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
      final existingBatch = await WebStorageService.getBatchByDate(widget.date);
      if (existingBatch != null) {
        // Load the stored values from localStorage using a more comprehensive key
        final batchKey = 'batch_${widget.date.year}_${widget.date.month}_${widget.date.day}';
        final storedData = html.window.localStorage[batchKey];
        
        if (storedData != null) {
          final Map<String, dynamic> data = jsonDecode(storedData);
          
          setState(() {
            _pattiQuantity = data['pattiQuantity']?.toDouble() ?? 0;
            _pattiRate = data['pattiRate']?.toDouble() ?? 0;
            _pdQuantity = data['pdQuantity']?.toDouble();
            _customRates = Map<String, double>.from(data['customRates'] ?? {});
            _manualEntries = List<Map<String, dynamic>>.from(data['manualEntries'] ?? []);
            
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
      }
    } catch (e) {
      print('Error loading existing batch: $e');
    }
  }

  void _recalculate() {
    if (_calculationEngine == null) return;

    // Auto-save data as user types
    _autoSaveData();

    // Use a timer to debounce rapid changes
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      
      // Validate inputs
      final errors = _calculationEngine!.validateInputs(
        pattiQuantity: _pattiQuantity,
        pattiRate: _pattiRate,
        pdQuantity: _pdQuantity,
        customRates: _customRates,
      );

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

      if (mounted) {
        setState(() {
          _validationErrors = errors;
          _currentResult = result;
        });
      }
    });
  }
  
  void _autoSaveData() {
    try {
      final batchKey = 'batch_${widget.date.year}_${widget.date.month}_${widget.date.day}';
      final batchData = {
        'pattiQuantity': _pattiQuantity,
        'pattiRate': _pattiRate,
        'pdQuantity': _pdQuantity,
        'customRates': _customRates,
        'manualEntries': _manualEntries,
        'autoSavedAt': DateTime.now().toIso8601String(),
      };
      html.window.localStorage[batchKey] = jsonEncode(batchData);
    } catch (e) {
      print('Auto-save failed: $e');
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
            Text(
              dateFormat.format(widget.date),
              style: AppTheme.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: _saveBatch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: Colors.white,
              elevation: 2,
            ),
            icon: const Icon(Icons.save),
            label: const Text('Save Batch'),
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
              icon: Icon(Icons.inventory_2, color: AppColors.rawMaterial),
            ),
            Tab(
              text: 'Production', 
              icon: Icon(Icons.precision_manufacturing, color: AppColors.product),
            ),
            Tab(
              text: 'Results',
              icon: Icon(Icons.assessment, color: AppColors.info),
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
          // Validation Errors
          if (_validationErrors.isNotEmpty) ...[
            PremiumCard(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacing6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius4),
                          ),
                          child: Icon(
                            Icons.error_outline, 
                            color: AppColors.error, 
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        Text(
                          'Validation Errors',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    ..._validationErrors.map((error) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacing4),
                        child: Text(
                          '• $error', 
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Base Material Input
          PremiumCard(
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
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'Enter the primary raw material quantity and rate',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pattiQuantityController,
                          decoration: const InputDecoration(
                            labelText: 'Patti Quantity (kg)',
                            hintText: 'Enter quantity',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _pattiQuantity = double.tryParse(value) ?? 0;
                            _recalculate();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _pattiRateController,
                          decoration: const InputDecoration(
                            labelText: 'Patti Rate (₹/kg)',
                            hintText: 'Enter rate',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _pattiRate = double.tryParse(value) ?? 0;
                            _recalculate();
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_pattiQuantity > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Amount: ₹${(_pattiQuantity * _pattiRate).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Auto-calculated Materials
          if (_pattiQuantity > 0 && _defaults != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-calculated Materials',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Byproduct Materials',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildEditableMaterialDisplay('CU', _pattiQuantity * (_defaults!.cuPercentage / 100), _defaults!.defaultCuRate, 'cu'),
                    _buildEditableMaterialDisplay('TIN', _pattiQuantity * (_defaults!.tinNumerator / _defaults!.tinDenominator), _defaults!.defaultTinRate, 'tin'),
                  ],
                ),
              ),
            ),
          ],

          // Manual Income/Expense Entries
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Manual Entries',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addManualEntry,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Entry'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_manualEntries.isEmpty)
                    Text(
                      'No manual entries added. Use \"Add Entry\" to include custom income or expenses.',
                      style: TextStyle(color: Colors.grey[600]),
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
      return const Center(
        child: Text(
          'Enter Patti quantity and rate to see results',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final result = _currentResult!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // P&L Summary
          Card(
            color: result.isProfitNegative ? Colors.red.shade50 : Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        result.isProfitNegative ? Icons.trending_down : Icons.trending_up,
                        color: result.isProfitNegative ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Net P&L Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                    const Divider(),
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
          const SizedBox(height: 16),

          // Excel Formula Cost Breakdown
          Card(
            color: _getCostBreakdownColor(result),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COST BREAKDOWN (Excel Formula)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCostBreakdownRow('Phase 1 Total Cost (E13)', result.phase1WithOther),
                  _buildCostBreakdownRow('TIN Expenses (E36)', result.tinCost, isExpense: true),
                  _buildCostBreakdownRow('PD Profit (E25)', result.pnl, isIncome: true),
                  _buildCostBreakdownRow('CU Income (E35)', result.cuIncome, isIncome: true),
                  const Divider(),
                  _buildCostBreakdownRow('Total Cost', result.totalCost, isTotal: true),
                  _buildCostBreakdownRow('PD Quantity', _pdQuantity ?? 0, unit: 'kg'),
                  const Divider(),
                  _buildCostBreakdownRow('Cost per 1 KG PD', result.costPer1kgPd, isResult: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Efficiency Metrics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Efficiency Metrics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
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

  Widget _buildMaterialDisplay(String name, double quantity, double rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text('${quantity.toStringAsFixed(2)} kg'),
          ),
          Expanded(
            child: Text('₹${rate.toStringAsFixed(2)}'),
          ),
          Expanded(
            child: Text(
              '₹${(quantity * rate).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableMaterialDisplay(String name, double quantity, double defaultRate, String rateKey) {
    final currentRate = _customRates[rateKey] ?? defaultRate;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text('${quantity.toStringAsFixed(2)} kg'),
          ),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextFormField(
                initialValue: currentRate.toStringAsFixed(2),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  border: const OutlineInputBorder(),
                  hintText: '₹/kg',
                  isDense: true,
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
          ),
          Expanded(
            child: Text(
              '₹${(quantity * currentRate).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryRow(int index, Map<String, dynamic> entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              entry['description'] ?? 'Manual Entry',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              entry['type'] == 'income' ? 'Income' : 'Expense',
              style: TextStyle(
                color: entry['type'] == 'income' ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '₹${entry['amount']?.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: entry['type'] == 'income' ? Colors.green : Colors.red,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _removeManualEntry(index),
          ),
        ],
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
          title: const Text('Add Manual Entry'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g., Transport, Maintenance',
                    ),
                    onChanged: (value) => description = value,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      hintText: 'Enter amount',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => amount = double.tryParse(value) ?? 0,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Type',
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
              child: const Text('Cancel'),
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
    
    if (ratio < 0.8) return Colors.green.shade50; // Good - Total Cost < 80% of PD Income
    if (ratio < 0.95) return Colors.yellow.shade50; // Warning - 80-95%
    return Colors.red.shade50; // Alert - > 95%
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
    if (isIncome) textColor = Colors.green.shade700;
    if (isExpense) textColor = Colors.red.shade700;
    if (isResult) textColor = Theme.of(context).colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal || isResult ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal || isResult ? 16 : 14,
            ),
          ),
          Text(
            valueText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal || isResult ? 16 : 14,
              color: textColor,
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

  Widget _buildMetricRow(String label, String value, {bool isValid = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              if (!isValid) ...[
                Icon(Icons.warning, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isValid ? null : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveBatch() async {
    try {
      if (_currentResult == null || _pattiQuantity <= 0 || _pattiRate <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter valid Patti quantity and rate before saving')),
        );
        return;
      }

      // Save input data to localStorage for editing later
      final batchKey = 'batch_${widget.date.year}_${widget.date.month}_${widget.date.day}';
      final batchData = {
        'pattiQuantity': _pattiQuantity,
        'pattiRate': _pattiRate,
        'pdQuantity': _pdQuantity,
        'customRates': _customRates,
        'savedAt': DateTime.now().toIso8601String(),
      };
      html.window.localStorage[batchKey] = jsonEncode(batchData);

      // Save batch summary to main storage
      final batch = ProductionBatch(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: widget.date,
        materials: [],
        totalExpenses: _currentResult!.phase1TotalCost,
        totalIncome: _currentResult!.pdIncome,
        netPnL: _currentResult!.netProfit,
        pdEfficiency: _currentResult!.pdEfficiency,
        status: BatchStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await WebStorageService.saveBatch(batch);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch saved successfully!')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving batch: $e')),
      );
    }
  }
}