import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/production_batch.dart';
import '../models/configurable_defaults.dart';
import '../theme/app_colors.dart';

/// Export service for generating PDF, Excel, and CSV reports
class ExportService {
  static ExportService? _instance;
  
  // Private constructor
  ExportService._();
  
  /// Get singleton instance
  static ExportService get instance {
    _instance ??= ExportService._();
    return _instance!;
  }
  
  /// Date formatters
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _fileNameFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timestampFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  
  /// Export single batch as PDF
  Future<File> exportBatchToPDF(ProductionBatch batch) async {
    final pdf = pw.Document();
    
    // Add page with batch details
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildPDFHeader(batch),
            pw.SizedBox(height: 20),
            _buildBatchSummary(batch),
            pw.SizedBox(height: 20),
            _buildMaterialsSection(batch),
            pw.SizedBox(height: 20),
            _buildCalculationResults(batch),
            pw.SizedBox(height: 20),
            _buildPDFFooter(),
          ];
        },
      ),
    );
    
    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'batch_${_fileNameFormat.format(batch.date)}.pdf';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());
    return file;
  }
  
  /// Export multiple batches as PDF
  Future<File> exportBatchesToPDF(List<ProductionBatch> batches, {
    String? title,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    
    // Add summary page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildReportHeader(title ?? 'Production Batches Report', startDate, endDate),
            pw.SizedBox(height: 20),
            _buildBatchesSummary(batches),
            pw.SizedBox(height: 20),
            _buildBatchesTable(batches),
            pw.SizedBox(height: 20),
            _buildPDFFooter(),
          ];
        },
      ),
    );
    
    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final dateRange = startDate != null && endDate != null 
        ? '${_fileNameFormat.format(startDate)}_to_${_fileNameFormat.format(endDate)}'
        : _fileNameFormat.format(DateTime.now());
    final fileName = 'batches_report_$dateRange.pdf';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());
    return file;
  }
  
  /// Export batches to Excel
  Future<File> exportBatchesToExcel(List<ProductionBatch> batches, {
    String? title,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final excel = Excel.createExcel();
    
    // Remove default sheet
    excel.delete('Sheet1');
    
    // Create summary sheet
    final summarySheet = excel['Summary'];
    _buildExcelSummary(summarySheet, batches, title, startDate, endDate);
    
    // Create detailed data sheet
    final dataSheet = excel['Batch Data'];
    _buildExcelBatchData(dataSheet, batches);
    
    // Create materials sheet
    final materialsSheet = excel['Materials'];
    _buildExcelMaterialsData(materialsSheet, batches);
    
    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final dateRange = startDate != null && endDate != null 
        ? '${_fileNameFormat.format(startDate)}_to_${_fileNameFormat.format(endDate)}'
        : _fileNameFormat.format(DateTime.now());
    final fileName = 'batches_report_$dateRange.xlsx';
    final file = File('${directory.path}/$fileName');
    
    final bytes = excel.save();
    await file.writeAsBytes(bytes!);
    return file;
  }
  
  /// Export batches to CSV
  Future<File> exportBatchesToCSV(List<ProductionBatch> batches) async {
    final List<List<dynamic>> csvData = [];
    
    // Add headers
    csvData.add([
      'Date',
      'Patti Quantity',
      'Patti Rate',
      'Total Revenue',
      'Total Cost',
      'Profit/Loss',
      'Efficiency %',
      'Base Materials Cost',
      'Derived Materials Cost',
      'Byproduct Revenue',
      'Labor Cost',
      'Rent Cost',
      'Account Cost',
      'Status'
    ]);
    
    // Add data rows
    for (final batch in batches) {
      final result = batch.calculationResult;
      csvData.add([
        _dateFormat.format(batch.date),
        batch.pattiQuantity,
        batch.pattiRate,
        batch.pattiQuantity * batch.pattiRate,
        result?.totalCost ?? 0,
        result?.finalProfitLoss ?? 0,
        result?.pdEfficiency ?? 0,
        result?.phase1TotalCost ?? 0,
        0, // derivedMaterialsCost - not available in mobile model
        result?.netByproductIncome ?? 0,
        0, // laborCost - not available in mobile model
        0, // rentCost - not available in mobile model
        0, // accountCost - not available in mobile model
        _getBatchStatus(batch),
      ]);
    }
    
    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(csvData);
    
    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'batches_export_${_fileNameFormat.format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(csvString);
    return file;
  }
  
  /// Share exported file
  Future<void> shareFile(File file, {String? subject}) async {
    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], subject: subject);
  }
  
  /// Export analytics summary as PDF
  Future<File> exportAnalyticsToPDF(List<ProductionBatch> batches, {
    required String period,
    required Map<String, dynamic> analytics,
  }) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildAnalyticsHeader(period),
            pw.SizedBox(height: 20),
            _buildAnalyticsMetrics(analytics),
            pw.SizedBox(height: 20),
            _buildTopPerformingBatches(batches),
            pw.SizedBox(height: 20),
            _buildTrendAnalysis(batches),
            pw.SizedBox(height: 20),
            _buildPDFFooter(),
          ];
        },
      ),
    );
    
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'analytics_${period.toLowerCase()}_${_fileNameFormat.format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsBytes(await pdf.save());
    return file;
  }
  
  /// Build PDF header for single batch
  pw.Widget _buildPDFHeader(ProductionBatch batch) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Chemical Process Tracker',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Production Batch Report',
          style: pw.TextStyle(
            fontSize: 18,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Date: ${_dateFormat.format(batch.date)}',
          style: pw.TextStyle(
            fontSize: 14,
            color: PdfColors.grey600,
          ),
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue800),
      ],
    );
  }
  
  /// Build batch summary section
  pw.Widget _buildBatchSummary(ProductionBatch batch) {
    final result = batch.calculationResult;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Batch Summary',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Patti Quantity: ${batch.pattiQuantity} kg'),
                pw.Text('Patti Rate: ₹${batch.pattiRate}/kg'),
                pw.Text('Total Revenue: ₹${(batch.pattiQuantity * batch.pattiRate).toStringAsFixed(2)}'),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Total Cost: ₹${result?.totalCost?.toStringAsFixed(2) ?? 'N/A'}'),
                pw.Text('Profit/Loss: ₹${result?.finalProfitLoss?.toStringAsFixed(2) ?? 'N/A'}'),
                pw.Text('Efficiency: ${result?.pdEfficiency?.toStringAsFixed(4) ?? 'N/A'}%'),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  /// Build materials section
  pw.Widget _buildMaterialsSection(ProductionBatch batch) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Materials',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Patti Quantity: ${batch.pattiQuantity} kg @ ₹${batch.pattiRate}/kg'),
        pw.SizedBox(height: 8),
        if (batch.pdQuantity != null) ...[
          pw.Text('PD Quantity: ${batch.pdQuantity} kg'),
          pw.SizedBox(height: 8),
        ],
        if (batch.manualEntries.isNotEmpty) ...[
          pw.Text('Manual Entries:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ...batch.manualEntries.map((entry) => pw.Text('• ${entry['name'] ?? 'N/A'}: ${entry['description'] ?? 'N/A'}')),
        ],
      ],
    );
  }
  
  /// Build calculation results section
  pw.Widget _buildCalculationResults(ProductionBatch batch) {
    final result = batch.calculationResult;
    if (result == null) return pw.Container();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Cost Breakdown',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount (₹)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Phase 1 Cost')),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(result.phase1TotalCost.toStringAsFixed(2))),
            ]),
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('PD Income')),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(result.pdIncome.toStringAsFixed(2))),
            ]),
            pw.TableRow(children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Byproduct Income')),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(result.netByproductIncome.toStringAsFixed(2))),
            ]),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Total Cost', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(result.totalCost.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  /// Build report header for multiple batches
  pw.Widget _buildReportHeader(String title, DateTime? startDate, DateTime? endDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Chemical Process Tracker',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        if (startDate != null && endDate != null)
          pw.Text(
            'Period: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey600,
            ),
          ),
        pw.Text(
          'Generated: ${_timestampFormat.format(DateTime.now())}',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey500,
          ),
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue800),
      ],
    );
  }
  
  /// Build batches summary
  pw.Widget _buildBatchesSummary(List<ProductionBatch> batches) {
    final totalBatches = batches.length;
    final totalRevenue = batches.fold(0.0, (sum, batch) => sum + (batch.pattiQuantity * batch.pattiRate));
    final totalCost = batches.fold(0.0, (sum, batch) => sum + (batch.calculationResult?.totalCost ?? 0));
    final totalProfit = totalRevenue - totalCost;
    final avgEfficiency = batches.where((b) => b.calculationResult != null).isEmpty 
        ? 0.0 
        : batches.where((b) => b.calculationResult != null).fold(0.0, (sum, batch) => sum + (batch.calculationResult?.pdEfficiency ?? 0)) / batches.where((b) => b.calculationResult != null).length;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Total Batches: $totalBatches'),
                pw.Text('Total Revenue: ₹${totalRevenue.toStringAsFixed(2)}'),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Total Cost: ₹${totalCost.toStringAsFixed(2)}'),
                pw.Text('Total Profit: ₹${totalProfit.toStringAsFixed(2)}'),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Average Efficiency: ${avgEfficiency.toStringAsFixed(4)}%'),
                pw.Text('Profit Margin: ${totalRevenue > 0 ? ((totalProfit / totalRevenue) * 100).toStringAsFixed(2) : '0.00'}%'),
              ],
            ),
          ],
        ),
      ],
    );
  }
  
  /// Build batches table
  pw.Widget _buildBatchesTable(List<ProductionBatch> batches) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Batch Details',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Revenue', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Cost', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('P&L', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Efficiency', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
              ],
            ),
            ...batches.map((batch) => pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_dateFormat.format(batch.date), style: const pw.TextStyle(fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${batch.pattiQuantity}', style: const pw.TextStyle(fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('₹${(batch.pattiQuantity * batch.pattiRate).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('₹${batch.calculationResult?.totalCost?.toStringAsFixed(0) ?? 'N/A'}', style: const pw.TextStyle(fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('₹${batch.calculationResult?.finalProfitLoss?.toStringAsFixed(0) ?? 'N/A'}', style: const pw.TextStyle(fontSize: 9))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${batch.calculationResult?.pdEfficiency?.toStringAsFixed(1) ?? 'N/A'}%', style: const pw.TextStyle(fontSize: 9))),
              ],
            )),
          ],
        ),
      ],
    );
  }
  
  /// Build PDF footer
  pw.Widget _buildPDFFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated by Chemical Process Tracker - Enterprise Edition',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey500,
          ),
        ),
        pw.Text(
          'Report generated on ${_timestampFormat.format(DateTime.now())}',
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey400,
          ),
        ),
      ],
    );
  }
  
  /// Build analytics header
  pw.Widget _buildAnalyticsHeader(String period) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Chemical Process Tracker',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Business Analytics Report',
          style: pw.TextStyle(
            fontSize: 18,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Period: $period',
          style: pw.TextStyle(
            fontSize: 14,
            color: PdfColors.grey600,
          ),
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue800),
      ],
    );
  }
  
  /// Build analytics metrics
  pw.Widget _buildAnalyticsMetrics(Map<String, dynamic> analytics) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Key Metrics',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Metric', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Value', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
            ...analytics.entries.map((entry) => pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(entry.key)),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(entry.value.toString())),
              ],
            )),
          ],
        ),
      ],
    );
  }
  
  /// Build top performing batches
  pw.Widget _buildTopPerformingBatches(List<ProductionBatch> batches) {
    final sortedBatches = batches.where((b) => b.calculationResult != null).toList();
    sortedBatches.sort((a, b) => (b.calculationResult?.finalProfitLoss ?? 0).compareTo(a.calculationResult?.finalProfitLoss ?? 0));
    final topBatches = sortedBatches.take(5).toList();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Top Performing Batches',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Profit/Loss', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Efficiency', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              ],
            ),
            ...topBatches.map((batch) => pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(_dateFormat.format(batch.date))),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('₹${batch.calculationResult?.finalProfitLoss?.toStringAsFixed(2) ?? 'N/A'}')),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${batch.calculationResult?.pdEfficiency?.toStringAsFixed(4) ?? 'N/A'}%')),
              ],
            )),
          ],
        ),
      ],
    );
  }
  
  /// Build trend analysis
  pw.Widget _buildTrendAnalysis(List<ProductionBatch> batches) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Trend Analysis',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text('• Total batches processed: ${batches.length}'),
        pw.Text('• Average profit per batch: ₹${batches.where((b) => b.calculationResult != null).isEmpty ? '0' : (batches.where((b) => b.calculationResult != null).fold(0.0, (sum, batch) => sum + (batch.calculationResult?.finalProfitLoss ?? 0)) / batches.where((b) => b.calculationResult != null).length).toStringAsFixed(2)}'),
        pw.Text('• Profitable batches: ${batches.where((b) => (b.calculationResult?.finalProfitLoss ?? 0) > 0).length}'),
        pw.Text('• Loss-making batches: ${batches.where((b) => (b.calculationResult?.finalProfitLoss ?? 0) < 0).length}'),
      ],
    );
  }
  
  /// Build Excel summary sheet
  void _buildExcelSummary(Sheet sheet, List<ProductionBatch> batches, String? title, DateTime? startDate, DateTime? endDate) {
    // Title
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue(title ?? 'Production Batches Report');
    sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(bold: true, fontSize: 16);
    
    // Period
    if (startDate != null && endDate != null) {
      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('Period: ${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}');
    }
    
    // Generated timestamp
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Generated: ${_timestampFormat.format(DateTime.now())}');
    
    // Summary metrics
    final totalBatches = batches.length;
    final totalRevenue = batches.fold(0.0, (sum, batch) => sum + (batch.pattiQuantity * batch.pattiRate));
    final totalCost = batches.fold(0.0, (sum, batch) => sum + (batch.calculationResult?.totalCost ?? 0));
    final totalProfit = totalRevenue - totalCost;
    
    sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Summary');
    sheet.cell(CellIndex.indexByString('A5')).cellStyle = CellStyle(bold: true, fontSize: 14);
    
    sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('Total Batches');
    sheet.cell(CellIndex.indexByString('B6')).value = IntCellValue(totalBatches);
    
    sheet.cell(CellIndex.indexByString('A7')).value = TextCellValue('Total Revenue');
    sheet.cell(CellIndex.indexByString('B7')).value = DoubleCellValue(totalRevenue);
    
    sheet.cell(CellIndex.indexByString('A8')).value = TextCellValue('Total Cost');
    sheet.cell(CellIndex.indexByString('B8')).value = DoubleCellValue(totalCost);
    
    sheet.cell(CellIndex.indexByString('A9')).value = TextCellValue('Total Profit');
    sheet.cell(CellIndex.indexByString('B9')).value = DoubleCellValue(totalProfit);
    
    sheet.cell(CellIndex.indexByString('A10')).value = TextCellValue('Profit Margin');
    sheet.cell(CellIndex.indexByString('B10')).value = TextCellValue(totalRevenue > 0 ? '${((totalProfit / totalRevenue) * 100).toStringAsFixed(2)}%' : '0.00%');
  }
  
  /// Build Excel batch data sheet
  void _buildExcelBatchData(Sheet sheet, List<ProductionBatch> batches) {
    // Headers
    final headers = ['Date', 'Patti Quantity', 'Patti Rate', 'Revenue', 'Total Cost', 'Profit/Loss', 'Efficiency %', 'Status'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = CellStyle(bold: true);
    }
    
    // Data rows
    for (int i = 0; i < batches.length; i++) {
      final batch = batches[i];
      final result = batch.calculationResult;
      
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value = TextCellValue(_dateFormat.format(batch.date));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: i + 1)).value = DoubleCellValue(batch.pattiQuantity);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: i + 1)).value = DoubleCellValue(batch.pattiRate);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: i + 1)).value = DoubleCellValue(batch.pattiQuantity * batch.pattiRate);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: i + 1)).value = DoubleCellValue(result?.totalCost ?? 0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: i + 1)).value = DoubleCellValue(result?.finalProfitLoss ?? 0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: i + 1)).value = DoubleCellValue(result?.pdEfficiency ?? 0);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: i + 1)).value = TextCellValue(_getBatchStatus(batch));
    }
  }
  
  /// Build Excel materials data sheet
  void _buildExcelMaterialsData(Sheet sheet, List<ProductionBatch> batches) {
    // Headers
    final headers = ['Date', 'Material Type', 'Material Name', 'Quantity', 'Rate', 'Cost'];
    for (int i = 0; i < headers.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value = TextCellValue(headers[i]);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = CellStyle(bold: true);
    }
    
    // Data rows
    int rowIndex = 1;
    for (final batch in batches) {
      final dateStr = _dateFormat.format(batch.date);
      
      // Patti materials
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(dateStr);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue('Patti');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue('Patti');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = DoubleCellValue(batch.pattiQuantity);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = DoubleCellValue(batch.pattiRate);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = DoubleCellValue(batch.pattiQuantity * batch.pattiRate);
      rowIndex++;
      
      // PD materials
      if (batch.pdQuantity != null) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(dateStr);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue('PD');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue('PD');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = DoubleCellValue(batch.pdQuantity!);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = DoubleCellValue(0.0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = DoubleCellValue(0.0);
        rowIndex++;
      }
      
      // Manual entries
      for (final entry in batch.manualEntries) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(dateStr);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue('Manual');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(entry['name']?.toString() ?? 'N/A');
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = DoubleCellValue(0.0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = DoubleCellValue(0.0);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = DoubleCellValue(0.0);
        rowIndex++;
      }
    }
  }
  
  /// Get batch status
  String _getBatchStatus(ProductionBatch batch) {
    if (batch.calculationResult == null) return 'Draft';
    if (batch.calculationResult!.finalProfitLoss > 0) return 'Profitable';
    if (batch.calculationResult!.finalProfitLoss < 0) return 'Loss';
    return 'Break-even';
  }
}