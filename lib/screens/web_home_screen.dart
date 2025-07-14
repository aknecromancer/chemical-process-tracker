import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/web_storage_service.dart';
import '../models/production_batch.dart';
import '../models/configurable_defaults.dart';
import '../services/calculation_engine.dart';
import 'web_batch_entry_screen.dart';
import 'settings_screen.dart';
import 'batch_history_screen.dart';
import '../widgets/analytics_dashboard.dart';

class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const DashboardTab(),
      const BatchHistoryTab(),
      const SettingsTab(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Batches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  ProductionBatch? todaysBatch;
  List<ProductionBatch> recentBatches = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final today = DateTime.now();
      
      // Check for today's batch
      todaysBatch = await WebStorageService.getBatchByDate(today);
      
      // Get all batches and sort them properly
      final allBatches = await WebStorageService.getAllBatches();
      allBatches.sort((a, b) => b.date.compareTo(a.date)); // Sort by date, newest first
      
      // Take the 10 most recent batches for better visibility
      recentBatches = allBatches.take(10).toList();
      
      print('Loaded ${recentBatches.length} recent batches');
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _createTodaysBatch() async {
    try {
      final today = DateTime.now();
      await WebStorageService.createBatch(today);
      await _loadData();
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebBatchEntryScreen(date: today),
          ),
        ).then((_) => _loadData());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating batch: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateFormat = DateFormat('EEEE, MMMM d, y');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chemical Process Tracker'),
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Header
                    Text(
                      dateFormat.format(today),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),

                    // Today's Batch Section
                    _buildTodaysBatchSection(),
                    const SizedBox(height: 24),

                    // Analytics Dashboard
                    AnalyticsDashboard(batches: recentBatches),
                    const SizedBox(height: 24),

                    // Recent Batches
                    _buildRecentBatches(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTodaysBatchSection() {
    if (todaysBatch == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'No batch created for today',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new production batch to start tracking today\'s materials and calculations.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _createTodaysBatch,
                icon: const Icon(Icons.add),
                label: const Text('Create Today\'s Batch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Batch',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Chip(
                  label: Text(todaysBatch!.statusDisplayName),
                  backgroundColor: _getStatusColor(todaysBatch!.status),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Net P&L',
                    '₹${todaysBatch!.netPnL.toStringAsFixed(0)}',
                    todaysBatch!.isProfitable ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'PD Efficiency',
                    '${todaysBatch!.pdEfficiency.toStringAsFixed(1)}%',
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WebBatchEntryScreen(date: DateTime.now()),
                    ),
                  ).then((_) => _loadData());
                },
                child: const Text('Continue Batch'),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildRecentBatches() {
    if (recentBatches.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No batches found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Create your first batch to start tracking production.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Batches',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...recentBatches.map((batch) => _buildBatchCard(batch)),
      ],
    );
  }

  Widget _buildBatchCard(ProductionBatch batch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(batch.status),
          child: Text(
            batch.date.day.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(batch.dateDisplayString),
        subtitle: Text('P&L: ₹${batch.netPnL.toStringAsFixed(0)} • Efficiency: ${batch.pdEfficiency.toStringAsFixed(1)}%'),
        trailing: Icon(
          batch.isProfitable ? Icons.trending_up : Icons.trending_down,
          color: batch.isProfitable ? Colors.green : Colors.red,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebBatchEntryScreen(date: batch.date),
            ),
          ).then((_) => _loadData());
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BatchStatus status) {
    switch (status) {
      case BatchStatus.draft:
        return Colors.orange;
      case BatchStatus.completed:
        return Colors.green;
      case BatchStatus.archived:
        return Colors.grey;
    }
  }
}

class BatchHistoryTab extends StatelessWidget {
  const BatchHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const BatchHistoryScreen();
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}