import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/batch_providers.dart';
import '../services/calculation_engine.dart';
import '../models/material_template.dart';

class EnhancedBatchEntryScreen extends ConsumerStatefulWidget {
  final DateTime date;
  
  const EnhancedBatchEntryScreen({super.key, required this.date});

  @override
  ConsumerState<EnhancedBatchEntryScreen> createState() => _EnhancedBatchEntryScreenState();
}

class _EnhancedBatchEntryScreenState extends ConsumerState<EnhancedBatchEntryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _pattiQuantityController = TextEditingController();
  final _pattiRateController = TextEditingController();
  final _pdQuantityController = TextEditingController();
  final _materialControllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pattiQuantityController.dispose();
    _pattiRateController.dispose();
    _pdQuantityController.dispose();
    _materialControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final batchNotifier = ref.watch(batchEntryProvider(widget.date).notifier);
    final batchState = ref.watch(batchEntryProvider(widget.date));
    final defaultRatesAsync = ref.watch(defaultRatesProvider);
    final formulaDisplaysAsync = ref.watch(formulaDisplaysProvider);

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
          _buildCopyPreviousButton(),
          _buildSaveButton(),
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
          _buildRawMaterialsTab(batchNotifier, batchState, defaultRatesAsync, formulaDisplaysAsync),
          _buildProductionTab(batchNotifier, batchState),
          _buildResultsTab(batchState),
        ],
      ),
    );
  }

  Widget _buildCopyPreviousButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.copy),
      tooltip: 'Copy Previous Data',
      onSelected: (value) => _copyPreviousData(value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'yesterday',
          child: ListTile(
            leading: Icon(Icons.today),
            title: Text('Copy Yesterday'),
            subtitle: Text('Copy rates from previous day'),
          ),
        ),
        const PopupMenuItem(
          value: 'week',
          child: ListTile(
            leading: Icon(Icons.date_range),
            title: Text('Copy Last Week'),
            subtitle: Text('Copy from same day last week'),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Consumer(
      builder: (context, ref, child) {
        final batchState = ref.watch(batchEntryProvider(widget.date));
        final isValid = batchState.pattiQuantity > 0 && 
                       batchState.pattiRate > 0 && 
                       batchState.validationErrors.isEmpty;
        
        return TextButton.icon(
          onPressed: isValid ? _saveBatch : null,
          icon: batchState.isLoading 
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('Save'),
        );
      },
    );
  }

  Widget _buildRawMaterialsTab(
    BatchEntryNotifier notifier,
    BatchEntryState state,
    AsyncValue<Map<String, double>> defaultRatesAsync,
    AsyncValue<Map<String, String>> formulaDisplaysAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Validation Errors
          if (state.validationErrors.isNotEmpty) ...[
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
                    ...state.validationErrors.map((error) => 
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
                            final quantity = double.tryParse(value) ?? 0;
                            notifier.updatePattiQuantity(quantity);
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
                            final rate = double.tryParse(value) ?? 0;
                            notifier.updatePattiRate(rate);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (state.pattiQuantity > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Amount: ₹${(state.pattiQuantity * state.pattiRate).toStringAsFixed(2)}',
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

          // Derived Materials
          if (state.pattiQuantity > 0) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Derived Materials (Auto-calculated)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...notifier.derivedMaterials.map((material) => 
                      _buildMaterialRow(material, notifier, isEditable: true)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Processing Materials
          if (state.pattiQuantity > 0) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Processing Materials',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    formulaDisplaysAsync.when(
                      data: (displays) => Column(
                        children: [
                          _buildFormulaDisplay('Worker Rate', displays['worker'] ?? ''),
                          _buildFormulaDisplay('Rent Rate', displays['rent'] ?? ''),
                          _buildFormulaDisplay('Account Rate', displays['account'] ?? ''),
                        ],
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Error: $error'),
                    ),
                    const SizedBox(height: 16),
                    ...notifier.rawMaterials.where((m) => m.materialId != 'patti').map((material) => 
                      _buildMaterialRow(material, notifier, isEditable: material.materialId == 'other')),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductionTab(BatchEntryNotifier notifier, BatchEntryState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Product
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pdQuantityController,
                          decoration: const InputDecoration(
                            labelText: 'PD Quantity (kg)',
                            hintText: 'Enter quantity',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final quantity = double.tryParse(value);
                            notifier.updatePdQuantity(quantity);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRateField('PD Rate (₹/kg)', 'pd', notifier, state),
                      ),
                    ],
                  ),
                  if (state.pdQuantity != null && state.pdQuantity! > 0) ...[
                    const SizedBox(height: 16),
                    _buildEfficiencyCard(state),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Byproducts
          if (state.pattiQuantity > 0) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Byproducts (Auto-calculated quantities)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...notifier.byproducts.map((material) => 
                      _buildMaterialRow(material, notifier, isEditable: true)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsTab(BatchEntryState state) {
    if (state.result == null) {
      return const Center(
        child: Text(
          'Enter Patti quantity and rate to see results',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final result = state.result!;
    
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
                  _buildPnLRow('Byproduct Income', result.netByproductIncome),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Phase Breakdown
          _buildPhaseCard('Phase 1: Processing Costs', result.phase1TotalCost, Colors.red),
          _buildPhaseCard('Phase 2: Product Income', result.pdIncome, Colors.blue),
          _buildPhaseCard('Phase 3: Byproduct Income', result.netByproductIncome, Colors.orange),
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
                  _buildMetricRow('Material Cost/Unit', '₹${result.materialCostPerUnit.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialRow(MaterialInput material, BatchEntryNotifier notifier, {bool isEditable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              material.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text('${material.quantity.toStringAsFixed(2)} kg'),
          ),
          Expanded(
            child: isEditable 
                ? _buildRateField('Rate', material.materialId, notifier, null)
                : Text('₹${material.rate.toStringAsFixed(2)}'),
          ),
          Expanded(
            child: Text(
              '₹${material.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateField(String label, String materialId, BatchEntryNotifier notifier, BatchEntryState? state) {
    final controller = _materialControllers.putIfAbsent(materialId, () => TextEditingController());
    
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final rate = double.tryParse(value) ?? 0;
        notifier.updateCustomRate(materialId, rate);
      },
    );
  }

  Widget _buildFormulaDisplay(String title, String formula) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(formula, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard(BatchEntryState state) {
    final efficiency = state.result?.pdEfficiency ?? 0;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.warning,
                color: isValid ? Colors.green : Colors.orange,
                size: 20,
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
          if (!isValid) ...[
            const SizedBox(height: 4),
            Text(
              'Efficiency should be between 0.1% and 10.0%',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
              ),
            ),
          ],
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

  Widget _buildPhaseCard(String title, double amount, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  void _copyPreviousData(String type) {
    // TODO: Implement copy previous data functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copy $type functionality coming soon')),
    );
  }

  void _saveBatch() {
    // TODO: Implement save batch functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Save functionality coming soon')),
    );
  }
}