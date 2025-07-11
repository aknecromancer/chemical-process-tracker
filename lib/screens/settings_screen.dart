import 'package:flutter/material.dart';
import '../models/configurable_defaults.dart';
import '../services/defaults_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ConfigurableDefaults? _defaults;
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Controllers for rate calculations
  final _workerAmountController = TextEditingController();
  final _rentAmountController = TextEditingController();
  final _accountAmountController = TextEditingController();
  final _denominatorController = TextEditingController();
  
  // Controllers for byproduct formulas
  final _cuPercentageController = TextEditingController();
  final _tinNumeratorController = TextEditingController();
  final _tinDenominatorController = TextEditingController();
  
  // Controllers for default rates
  final _pdRateController = TextEditingController();
  final _cuRateController = TextEditingController();
  final _tinRateController = TextEditingController();
  final _nitricRateController = TextEditingController();
  final _hclRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    try {
      final defaults = await DefaultsService.getDefaults();
      setState(() {
        _defaults = defaults;
        _populateControllers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  void _populateControllers() {
    if (_defaults == null) return;
    
    // Rate calculations
    _workerAmountController.text = _defaults!.workerFixedAmount.toString();
    _rentAmountController.text = _defaults!.rentFixedAmount.toString();
    _accountAmountController.text = _defaults!.accountFixedAmount.toString();
    _denominatorController.text = _defaults!.fixedDenominator.toString();
    
    // Byproduct formulas
    _cuPercentageController.text = _defaults!.cuPercentage.toString();
    _tinNumeratorController.text = _defaults!.tinNumerator.toString();
    _tinDenominatorController.text = _defaults!.tinDenominator.toString();
    
    // Default rates
    _pdRateController.text = _defaults!.defaultPdRate.toString();
    _cuRateController.text = _defaults!.defaultCuRate.toString();
    _tinRateController.text = _defaults!.defaultTinRate.toString();
    _nitricRateController.text = _defaults!.defaultNitricRate.toString();
    _hclRateController.text = _defaults!.defaultHclRate.toString();
  }

  Future<void> _saveSettings() async {
    if (_defaults == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final updatedDefaults = _defaults!.copyWith(
        // Rate calculations
        workerFixedAmount: double.tryParse(_workerAmountController.text) ?? _defaults!.workerFixedAmount,
        rentFixedAmount: double.tryParse(_rentAmountController.text) ?? _defaults!.rentFixedAmount,
        accountFixedAmount: double.tryParse(_accountAmountController.text) ?? _defaults!.accountFixedAmount,
        fixedDenominator: double.tryParse(_denominatorController.text) ?? _defaults!.fixedDenominator,
        
        // Byproduct formulas
        cuPercentage: double.tryParse(_cuPercentageController.text) ?? _defaults!.cuPercentage,
        tinNumerator: double.tryParse(_tinNumeratorController.text) ?? _defaults!.tinNumerator,
        tinDenominator: double.tryParse(_tinDenominatorController.text) ?? _defaults!.tinDenominator,
        
        // Default rates
        defaultPdRate: double.tryParse(_pdRateController.text) ?? _defaults!.defaultPdRate,
        defaultCuRate: double.tryParse(_cuRateController.text) ?? _defaults!.defaultCuRate,
        defaultTinRate: double.tryParse(_tinRateController.text) ?? _defaults!.defaultTinRate,
        defaultNitricRate: double.tryParse(_nitricRateController.text) ?? _defaults!.defaultNitricRate,
        defaultHclRate: double.tryParse(_hclRateController.text) ?? _defaults!.defaultHclRate,
        
        updatedAt: DateTime.now(),
      );
      
      await DefaultsService.updateDefaults(updatedDefaults);
      
      setState(() {
        _defaults = updatedDefaults;
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all settings to factory defaults? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        await DefaultsService.resetToDefaults();
        await _loadDefaults();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings reset to factory defaults'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error resetting settings: $e')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _workerAmountController.dispose();
    _rentAmountController.dispose();
    _accountAmountController.dispose();
    _denominatorController.dispose();
    _cuPercentageController.dispose();
    _tinNumeratorController.dispose();
    _tinDenominatorController.dispose();
    _pdRateController.dispose();
    _cuRateController.dispose();
    _tinRateController.dispose();
    _nitricRateController.dispose();
    _hclRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Defaults'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _resetToDefaults,
            icon: const Icon(Icons.restore),
            label: const Text('Reset'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveSettings,
            icon: _isSaving 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Saving...' : 'Save'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRateCalculationsSection(),
            const SizedBox(height: 24),
            _buildByproductFormulasSection(),
            const SizedBox(height: 24),
            _buildDefaultRatesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRateCalculationsSection() {
    if (_defaults == null) return const SizedBox();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rate Calculations',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure the formula components for Worker, Rent, and Account rates',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // Fixed Denominator
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _denominatorController,
                    decoration: const InputDecoration(
                      labelText: 'Fixed Denominator',
                      hintText: '4500',
                      helperText: 'Used in all rate calculations',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Worker Rate
            _buildRateCalculationRow(
              'Worker Rate',
              _workerAmountController,
              '38000',
              _defaults!.calculatedWorkerRate,
              'Worker Fixed Amount ÷ Fixed Denominator',
            ),
            const SizedBox(height: 16),
            
            // Rent Rate
            _buildRateCalculationRow(
              'Rent Rate',
              _rentAmountController,
              '25000',
              _defaults!.calculatedRentRate,
            ),
            const SizedBox(height: 16),
            
            // Account Rate
            _buildRateCalculationRow(
              'Account Rate',
              _accountAmountController,
              '5000',
              _defaults!.calculatedAccountRate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateCalculationRow(
    String title,
    TextEditingController controller,
    String placeholder,
    double calculatedRate, [
    String? description,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null) ...[
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Fixed Amount',
                  hintText: placeholder,
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₹${calculatedRate.toStringAsFixed(3)}/kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildByproductFormulasSection() {
    if (_defaults == null) return const SizedBox();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Byproduct Formulas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure quantity calculations for CU and TIN materials',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // CU Formula
            Text(
              'CU Quantity = Patti Quantity × CU Percentage',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'CU Percentage',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _cuPercentageController,
                    decoration: const InputDecoration(
                      labelText: 'Percentage',
                      hintText: '10.0',
                      suffixText: '%',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Example: 200kg → ${(200 * (_defaults!.cuPercentage / 100)).toStringAsFixed(1)}kg',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // TIN Formula
            Text(
              'TIN Quantity = (TIN Numerator ÷ TIN Denominator) × Patti Quantity',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'TIN Formula',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _tinNumeratorController,
                    decoration: const InputDecoration(
                      labelText: 'Numerator',
                      hintText: '11',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('÷', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _tinDenominatorController,
                    decoration: const InputDecoration(
                      labelText: 'Denominator',
                      hintText: '30',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Example: 200kg → ${(200 * (_defaults!.tinNumerator / _defaults!.tinDenominator)).toStringAsFixed(2)}kg',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
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

  Widget _buildDefaultRatesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default Material Rates',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set default rates that will be used for all new batches (can be overridden per batch)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            // Product Rates
            Text(
              'Product Rates',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildRateField('PD Rate', _pdRateController, '12000'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRateField('CU Rate', _cuRateController, '600'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRateField('TIN Rate', _tinRateController, '38'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Chemical Rates
            Text(
              'Chemical Rates',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildRateField('Nitric Rate', _nitricRateController, '26'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRateField('HCL Rate', _hclRateController, '1.7'),
                ),
                const SizedBox(width: 16),
                Expanded(child: Container()), // Empty space for alignment
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateField(String label, TextEditingController controller, String placeholder) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        suffixText: '₹/kg',
        isDense: true,
      ),
      keyboardType: TextInputType.number,
    );
  }
}