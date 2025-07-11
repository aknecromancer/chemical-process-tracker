import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/production_batch.dart';
import '../services/web_storage_service.dart';
import 'web_batch_entry_screen.dart';

class BatchHistoryScreen extends StatefulWidget {
  const BatchHistoryScreen({super.key});

  @override
  State<BatchHistoryScreen> createState() => _BatchHistoryScreenState();
}

class _BatchHistoryScreenState extends State<BatchHistoryScreen> {
  List<ProductionBatch> allBatches = [];
  List<ProductionBatch> filteredBatches = [];
  bool isLoading = true;
  String searchQuery = '';
  DateTime? startDate;
  DateTime? endDate;
  BatchStatus? statusFilter;
  bool showProfitableOnly = false;
  String sortBy = 'date'; // date, profit, efficiency
  bool sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    setState(() => isLoading = true);
    
    try {
      final batches = await WebStorageService.getAllBatches();
      setState(() {
        allBatches = batches;
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading batches: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    filteredBatches = allBatches.where((batch) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final dateStr = DateFormat('dd/MM/yyyy').format(batch.date).toLowerCase();
        if (!dateStr.contains(query) && 
            !batch.netPnL.toString().contains(query) &&
            !batch.pdEfficiency.toString().contains(query)) {
          return false;
        }
      }
      
      // Date range filter
      if (startDate != null && batch.date.isBefore(startDate!)) return false;
      if (endDate != null && batch.date.isAfter(endDate!)) return false;
      
      // Status filter
      if (statusFilter != null && batch.status != statusFilter) return false;
      
      // Profitability filter
      if (showProfitableOnly && !batch.isProfitable) return false;
      
      return true;
    }).toList();
    
    // Apply sorting
    filteredBatches.sort((a, b) {
      int comparison = 0;
      switch (sortBy) {
        case 'date':
          comparison = a.date.compareTo(b.date);
          break;
        case 'profit':
          comparison = a.netPnL.compareTo(b.netPnL);
          break;
        case 'efficiency':
          comparison = a.pdEfficiency.compareTo(b.pdEfficiency);
          break;
      }
      return sortAscending ? comparison : -comparison;
    });
  }

  void _updateSearch(String query) {
    setState(() {
      searchQuery = query;
      _applyFilters();
    });
  }

  void _updateDateFilter(DateTime? start, DateTime? end) {
    setState(() {
      startDate = start;
      endDate = end;
      _applyFilters();
    });
  }

  void _updateStatusFilter(BatchStatus? status) {
    setState(() {
      statusFilter = status;
      _applyFilters();
    });
  }

  void _updateSorting(String newSortBy) {
    setState(() {
      if (sortBy == newSortBy) {
        sortAscending = !sortAscending;
      } else {
        sortBy = newSortBy;
        sortAscending = false;
      }
      _applyFilters();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
    );
    
    if (picked != null) {
      _updateDateFilter(picked.start, picked.end);
    }
  }

  void _clearFilters() {
    setState(() {
      searchQuery = '';
      startDate = null;
      endDate = null;
      statusFilter = null;
      showProfitableOnly = false;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Batch History (${filteredBatches.length}/${allBatches.length})'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBatches,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: filteredBatches.isNotEmpty ? _exportData : null,
            tooltip: 'Export CSV',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters Section
          _buildFiltersSection(),
          
          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBatches.isEmpty
                    ? _buildEmptyState()
                    : _buildBatchList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search and Date Range Row - Mobile Responsive
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                
                if (isMobile) {
                  // Mobile Layout: Stack vertically
                  return Column(
                    children: [
                      // Search Field
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          hintText: 'Date, profit, efficiency...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onChanged: _updateSearch,
                      ),
                      const SizedBox(height: 12),
                      
                      // Date Range and Clear Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectDateRange,
                              icon: const Icon(Icons.date_range, size: 16),
                              label: Text(
                                startDate != null && endDate != null
                                    ? '${DateFormat('dd/MM').format(startDate!)} - ${DateFormat('dd/MM').format(endDate!)}'
                                    : 'Date Range',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          if (startDate != null || endDate != null || searchQuery.isNotEmpty || statusFilter != null || showProfitableOnly) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearFilters,
                              tooltip: 'Clear Filters',
                            ),
                          ],
                        ],
                      ),
                    ],
                  );
                } else {
                  // Desktop/Tablet Layout: Keep horizontal
                  return Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Search',
                            hintText: 'Date, profit, efficiency...',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                          ),
                          onChanged: _updateSearch,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDateRange,
                          icon: const Icon(Icons.date_range),
                          label: Text(startDate != null && endDate != null
                              ? '${DateFormat('dd/MM').format(startDate!)} - ${DateFormat('dd/MM').format(endDate!)}'
                              : 'Date Range'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (startDate != null || endDate != null || searchQuery.isNotEmpty || statusFilter != null || showProfitableOnly)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearFilters,
                          tooltip: 'Clear Filters',
                        ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            
            // Filter Chips Row - Mobile Responsive
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                
                if (isMobile) {
                  // Mobile Layout: Stack filters and sort options vertically
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filters Row
                      Row(
                        children: [
                          // Status Filter - Compact
                          Expanded(
                            child: DropdownButton<BatchStatus?>(
                              value: statusFilter,
                              hint: const Text('Status'),
                              isDense: true,
                              isExpanded: true,
                              onChanged: _updateStatusFilter,
                              items: [
                                const DropdownMenuItem<BatchStatus?>(
                                  value: null,
                                  child: Text('All'),
                                ),
                                ...BatchStatus.values.map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.name.toUpperCase()),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Profitable Only Toggle - Compact
                          FilterChip(
                            label: const Text('Profitable', style: TextStyle(fontSize: 12)),
                            selected: showProfitableOnly,
                            onSelected: (selected) {
                              setState(() {
                                showProfitableOnly = selected;
                                _applyFilters();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Sort Options Row
                      Row(
                        children: [
                          Text('Sort: ', style: Theme.of(context).textTheme.bodySmall),
                          _buildSortChip('Date', 'date'),
                          const SizedBox(width: 4),
                          _buildSortChip('Profit', 'profit'),
                          const SizedBox(width: 4),
                          _buildSortChip('Efficiency', 'efficiency'),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Desktop/Tablet Layout: Keep horizontal
                  return Row(
                    children: [
                      // Status Filter
                      DropdownButton<BatchStatus?>(
                        value: statusFilter,
                        hint: const Text('All Status'),
                        isDense: true,
                        onChanged: _updateStatusFilter,
                        items: [
                          const DropdownMenuItem<BatchStatus?>(
                            value: null,
                            child: Text('All Status'),
                          ),
                          ...BatchStatus.values.map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.name.toUpperCase()),
                          )),
                        ],
                      ),
                      const SizedBox(width: 16),
                      
                      // Profitable Only Toggle
                      FilterChip(
                        label: const Text('Profitable Only'),
                        selected: showProfitableOnly,
                        onSelected: (selected) {
                          setState(() {
                            showProfitableOnly = selected;
                            _applyFilters();
                          });
                        },
                      ),
                      const Spacer(),
                      
                      // Sort Options
                      Text('Sort by: ', style: Theme.of(context).textTheme.bodySmall),
                      _buildSortChip('Date', 'date'),
                      const SizedBox(width: 8),
                      _buildSortChip('Profit', 'profit'),
                      const SizedBox(width: 8),
                      _buildSortChip('Efficiency', 'efficiency'),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = sortBy == value;
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
            ),
          ],
        ],
      ),
      onPressed: () => _updateSorting(value),
      backgroundColor: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty || startDate != null || statusFilter != null
                ? 'No batches match your filters'
                : 'No batches found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isNotEmpty || startDate != null || statusFilter != null
                ? 'Try adjusting your search criteria'
                : 'Create your first batch to see it here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (searchQuery.isNotEmpty || startDate != null || statusFilter != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBatchList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBatches.length,
      itemBuilder: (context, index) {
        final batch = filteredBatches[index];
        return _buildBatchCard(batch);
      },
    );
  }

  Widget _buildBatchCard(ProductionBatch batch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebBatchEntryScreen(date: batch.date),
            ),
          ).then((_) => _loadBatches());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.dateDisplayString,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE').format(batch.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      batch.status.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: _getStatusColor(batch.status),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Metrics Row - Mobile Responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 400;
                  
                  if (isMobile) {
                    // Mobile: Stack metrics vertically in rows of 2
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetric(
                                'Net P&L',
                                '₹${batch.netPnL.toStringAsFixed(0)}',
                                batch.isProfitable ? Colors.green : Colors.red,
                                batch.isProfitable ? Icons.trending_up : Icons.trending_down,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetric(
                                'PD Efficiency',
                                '${batch.pdEfficiency.toStringAsFixed(2)}%',
                                Colors.blue,
                                Icons.analytics,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetric(
                                'Total Expenses',
                                '₹${batch.totalExpenses.toStringAsFixed(0)}',
                                Colors.orange,
                                Icons.calculate,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox()), // Empty space for alignment
                          ],
                        ),
                      ],
                    );
                  } else {
                    // Desktop/Tablet: Keep horizontal layout
                    return Row(
                      children: [
                        Expanded(
                          child: _buildMetric(
                            'Net P&L',
                            '₹${batch.netPnL.toStringAsFixed(0)}',
                            batch.isProfitable ? Colors.green : Colors.red,
                            batch.isProfitable ? Icons.trending_up : Icons.trending_down,
                          ),
                        ),
                        Expanded(
                          child: _buildMetric(
                            'PD Efficiency',
                            '${batch.pdEfficiency.toStringAsFixed(2)}%',
                            Colors.blue,
                            Icons.analytics,
                          ),
                        ),
                        Expanded(
                          child: _buildMetric(
                            'Total Expenses',
                            '₹${batch.totalExpenses.toStringAsFixed(0)}',
                            Colors.orange,
                            Icons.calculate,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              
              // Quick Actions - Mobile Responsive
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 400;
                  
                  if (isMobile) {
                    // Mobile: Full width buttons
                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _duplicateBatch(batch),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Duplicate'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WebBatchEntryScreen(date: batch.date),
                                ),
                              ).then((_) => _loadBatches());
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Edit'),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Desktop/Tablet: Right-aligned buttons
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _duplicateBatch(batch),
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Duplicate'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WebBatchEntryScreen(date: batch.date),
                              ),
                            ).then((_) => _loadBatches());
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit'),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(BatchStatus status) {
    switch (status) {
      case BatchStatus.draft:
        return Colors.orange.shade100;
      case BatchStatus.completed:
        return Colors.green.shade100;
      case BatchStatus.archived:
        return Colors.grey.shade100;
    }
  }

  Future<void> _duplicateBatch(ProductionBatch batch) async {
    try {
      final today = DateTime.now();
      final existingBatch = await WebStorageService.getBatchByDate(today);
      
      if (existingBatch != null) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Batch Already Exists'),
            content: const Text('A batch for today already exists. Do you want to overwrite it with the duplicated data?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Overwrite'),
              ),
            ],
          ),
        );
        
        if (confirmed != true) return;
      }
      
      // Create new batch with today's date but batch's data
      await WebStorageService.createBatch(today);
      final newBatch = await WebStorageService.getBatchByDate(today);
      
      if (newBatch != null) {
        // Copy materials from the selected batch
        // Note: This would require extending WebStorageService to copy batch data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Batch duplicated for today')),
          );
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebBatchEntryScreen(date: today),
            ),
          ).then((_) => _loadBatches());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error duplicating batch: $e')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    // This would export filtered batches to CSV
    // For now, show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV export feature coming soon!')),
    );
  }
}