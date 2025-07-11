import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../services/web_storage_service.dart';
import '../services/calculation_engine.dart';
import '../models/configurable_defaults.dart';
import '../models/production_batch.dart';

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

      // Calculate results
      final result = _calculationEngine!.calculateProcess(
        pattiQuantity: _pattiQuantity,
        pattiRate: _pattiRate,
        pdQuantity: _pdQuantity,
        customRates: _customRates,
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Batch Entry'),
            Text(
              dateFormat.format(widget.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveBatch,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Raw Materials', icon: Icon(Icons.inventory_2)),
            Tab(text: 'Production', icon: Icon(Icons.precision_manufacturing)),
            Tab(text: 'Results', icon: Icon(Icons.assessment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRawMaterialsTab(),
          _buildProductionTab(),
          _buildResultsTab(),
        ],
      ),
    );
  }

  Widget _buildRawMaterialsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Validation Errors
          if (_validationErrors.isNotEmpty) ...[
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Validation Errors',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._validationErrors.map((error) => 
                      Text('• $error', style: TextStyle(color: Colors.red.shade700))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Base Material Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Base Material',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
                    _buildMaterialDisplay('Nitric', _pattiQuantity * 1.4, _defaults!.defaultNitricRate),
                    _buildMaterialDisplay('HCL', _pattiQuantity * 1.4 * 3.0, _defaults!.defaultHclRate),
                    _buildMaterialDisplay('Worker', _pattiQuantity, _defaults!.calculatedWorkerRate),
                    _buildMaterialDisplay('Rent', _pattiQuantity, _defaults!.calculatedRentRate),
                    _buildMaterialDisplay('Account', _pattiQuantity, _defaults!.calculatedAccountRate),
                  ],
                ),
              ),
            ),
          ],
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
                  _buildMetricRow('Cost per 1kg PD', '₹${result.costPer1kgPd.toStringAsFixed(2)}'),
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

  Widget _buildPnLRow(String label, double amount, {bool isTotal = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
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