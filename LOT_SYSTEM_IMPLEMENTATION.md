# LOT-Based System Implementation Documentation

## 📋 **Overview**

This document provides a comprehensive guide to the LOT-based system implementation for the Chemical Process Tracker. This system represents a major architectural shift from date-based tracking to LOT-based multi-day production tracking.

## 🎯 **Business Requirements Addressed**

### **Original Problem**
- The system was date-based: one batch per day
- User feedback indicated need for LOT-based tracking where:
  - A LOT can span multiple days
  - LOT1 starts July 15th (draft), runs for 2 days, completed July 16th
  - Analytics should show LOT1 data under July 16th (completion date)

### **Solution Implemented**
- Complete LOT-based system with multi-day support
- Analytics driven by completion dates, not start dates
- LOT workflow: Draft → In Progress → Completed
- Automatic LOT numbering (LOT001, LOT002, etc.)

## 🏗️ **System Architecture**

### **Core Models**

#### **ProductionLot Model** (`lib/models/production_lot.dart`)
```dart
class ProductionLot {
  final String id;
  final String lotNumber;      // LOT001, LOT002, etc.
  final DateTime startDate;    // When LOT was created/started
  final DateTime? completedDate; // When LOT was completed
  final LotStatus status;      // draft, inProgress, completed, archived
  final double pattiQuantity;
  final double pattiRate;
  final double? pdQuantity;
  final Map<String, double> customRates;
  final List<Map<String, dynamic>> manualEntries;
  final CalculationResult? calculationResult;
  final String? notes;
  
  // Key business logic
  DateTime get reportingDate => completedDate ?? startDate; // Analytics use this
  int get durationInDays; // Multi-day support
  bool get isActive => status == LotStatus.inProgress;
  bool get isCompleted => status == LotStatus.completed;
}

enum LotStatus {
  draft,      // LOT created but not started
  inProgress, // LOT currently being processed
  completed,  // LOT completed (drives analytics)
  archived,   // LOT archived
}
```

### **Storage Layer**

#### **LotStorageService** (`lib/services/lot_storage_service.dart`)
- **Purpose**: Local storage for LOTs using SharedPreferences
- **Key Methods**:
  - `getAllLots()`: Get all LOTs
  - `getActiveLots()`: Get draft + in-progress LOTs
  - `getCompletedLots()`: Get completed LOTs (sorted by completion date)
  - `getLotsCompletedInRange(startDate, endDate)`: Analytics data source
  - `createNewLot()`: Auto-generates next LOT number
  - `markLotAsInProgress()`: Status transition
  - `completeLot()`: Status transition + sets completion date

#### **CloudStorageService** (`lib/services/cloud_storage_service.dart`)
- **Purpose**: Offline-first cloud sync with Supabase
- **LOT Support**: Added `saveLot()` method for cloud synchronization
- **Sync Operations**: Handles offline LOT operations with pending sync

### **Database Schema**

#### **Supabase Schema** (`supabase_schema.sql`)
```sql
-- LOT-based tracking table
CREATE TABLE production_lots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- LOT identification
    lot_number TEXT NOT NULL UNIQUE,
    start_date DATE NOT NULL,
    completed_date DATE,  -- Key for analytics
    status TEXT NOT NULL DEFAULT 'draft',
    
    -- Production data
    patti_quantity DECIMAL(10,2) DEFAULT 0.00,
    patti_rate DECIMAL(10,2) DEFAULT 0.00,
    pd_quantity DECIMAL(10,2),
    
    -- Flexible data storage
    custom_rates JSONB DEFAULT '{}'::jsonb,
    manual_entries JSONB DEFAULT '[]'::jsonb,
    calculation_result JSONB DEFAULT '{}'::jsonb,
    
    -- Metadata
    notes TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Critical indexes for performance
CREATE INDEX idx_production_lots_completed_date ON production_lots(completed_date);
CREATE INDEX idx_production_lots_status ON production_lots(status);
CREATE INDEX idx_production_lots_lot_number ON production_lots(lot_number);
```

## 🖥️ **User Interface Implementation**

### **Home Screen** (`lib/screens/mobile_home_screen.dart`)

#### **Navigation Structure**
```dart
final List<Widget> _screens = [
  const LotDashboardTab(),          // Main dashboard
  const MobileLotManagementScreen(), // LOT management
  const AnalyticsScreen(),           // LOT-based analytics
  const SettingsScreen(),            // Settings
];
```

#### **Dashboard Features**
1. **Active LOTs Section**: Shows draft and in-progress LOTs
2. **Quick Stats**: Total LOTs, Active, Profitable, Avg P&L
3. **Recent Completed**: Last 5 completed LOTs (by completion date)
4. **Create New LOT**: Primary action button

### **LOT Management Screen** (`lib/screens/mobile_lot_management_screen.dart`)

#### **Features**
- **LOT Listing**: All LOTs with filtering/sorting
- **Status Management**: Start/Complete LOT actions
- **Search & Filter**: By LOT number, status, dates
- **Sorting Options**: Start date, completion date, profit, LOT number
- **Bulk Actions**: Duplicate, delete LOTs

#### **Status Workflow**
```
Draft → [Start LOT] → In Progress → [Complete LOT] → Completed
```

### **LOT Entry Screen** (`lib/screens/mobile_lot_entry_screen.dart`)

#### **Data Entry Sections**
1. **LOT Information**: Number, dates, status, duration
2. **Patti Details**: Quantity, rate, PD quantity
3. **Materials & Costs**: Manual entries for materials
4. **Calculation Results**: Real-time P&L calculations
5. **Notes**: Free-text notes

#### **Status Actions**
- **Draft LOTs**: Can start or edit
- **In Progress LOTs**: Can complete or continue editing
- **Completed LOTs**: Read-only view

### **Analytics System** (`lib/screens/analytics_screen.dart`)

#### **LOT-Based Analytics** (`lib/widgets/lot_analytics_dashboard.dart`)
- **Data Source**: Completed LOTs filtered by completion date
- **Time Filters**: 7 days, 30 days, 90 days, 1 year
- **Key Metrics**:
  - Total LOTs vs Completed LOTs
  - Profitable LOTs count and percentage
  - Average P&L and efficiency by completion date
  - Success rate (profitable/total)

#### **Visualizations**
1. **Profit Trend Chart**: Line chart by LOT completion dates
2. **Efficiency Distribution**: Pie chart of efficiency ranges
3. **LOT Status Breakdown**: Status counts and percentages
4. **Profitability Analysis**: Total profit, loss, best/worst LOT

## ⚙️ **Configuration & Settings**

### **Auto-LOT Numbering**
```dart
static String generateNextLotNumber(List<ProductionLot> existingLots) {
  // Extracts numeric part: LOT001 → 1, LOT002 → 2
  // Returns next in sequence: LOT003
}
```

### **Multi-Day Duration Calculation**
```dart
int get durationInDays {
  if (completedDate != null) {
    return completedDate!.difference(startDate).inDays + 1;
  }
  return DateTime.now().difference(startDate).inDays + 1;
}
```

## 📊 **Analytics & Reporting Logic**

### **Completion Date Priority**
- **Analytics Data Source**: `getLotsCompletedInRange(startDate, endDate)`
- **Reporting Date**: `lot.reportingDate` (completion date if available, else start date)
- **Business Rule**: LOT data appears in analytics under completion date

### **Example Scenario**
```
LOT001: 
- Start Date: July 15th
- Completion Date: July 16th
- Analytics: Data shows under July 16th

LOT002:
- Start Date: July 20th  
- Still In Progress
- Analytics: Not included in completed LOT analytics
```

## 🔄 **Data Migration Strategy**

### **Backward Compatibility**
- Original batch system preserved in separate models
- Database schema supports both systems
- LOT system runs independently

### **Migration Approach** (Future)
```dart
/// Convert existing batches to LOTs
static Future<void> migrateBatchesToLots() async {
  // For each date-based batch:
  // 1. Create LOT with start_date = batch_date
  // 2. Set completed_date = batch_date (same day completion)
  // 3. Transfer all batch data to LOT format
  // 4. Preserve original batch for rollback
}
```

## 🧪 **Testing Strategy**

### **LOT Workflow Testing**
1. **Create LOT**: Verify auto-numbering (LOT001)
2. **Start LOT**: Draft → In Progress status change
3. **Multi-Day Test**: Create LOT today, complete tomorrow
4. **Analytics Test**: Verify data appears under completion date
5. **Duration Test**: Verify day calculation across dates

### **Data Integrity Testing**
- **Concurrent LOT Creation**: Ensure unique numbering
- **Status Transitions**: Verify valid state changes only
- **Analytics Accuracy**: Completion date filtering
- **Cloud Sync**: Offline → Online data consistency

## 📝 **API Reference**

### **Core LOT Operations**
```dart
// Create new LOT
LotStorageService.createNewLot() → ProductionLot

// Status transitions
LotStorageService.markLotAsInProgress(lotId) → ProductionLot
LotStorageService.completeLot(lotId) → ProductionLot

// Analytics data
LotStorageService.getLotsCompletedInRange(start, end) → List<ProductionLot>
LotStorageService.getAnalyticsData(lastDays: 30) → Map<String, dynamic>
```

### **Cloud Sync Operations**
```dart
// Save to cloud with offline support
CloudStorageService.saveLot(lot) → Future<void>

// Sync pending operations
CloudStorageService.syncAll() → Future<void>
```

## 🔧 **Configuration Files**

### **Key Dependencies** (`pubspec.yaml`)
```yaml
dependencies:
  shared_preferences: ^2.0.15    # Local storage
  supabase_flutter: ^1.10.24     # Cloud sync
  connectivity_plus: ^4.0.2      # Network detection
  intl: ^0.18.1                  # Date formatting
  fl_chart: ^0.64.0              # Analytics charts
```

### **Theme Configuration** (`lib/theme/app_theme.dart`)
- LOT status colors and styling
- Premium card designs for LOT display
- Consistent spacing and typography

## 🚀 **Deployment**

### **Build Commands**
```bash
# Debug build for testing
flutter build apk --debug

# Release build for production
flutter build apk --release
```

### **APK Locations**
- Debug: `build/app/outputs/flutter-apk/app-debug.apk`
- Release: `build/app/outputs/flutter-apk/app-release.apk`

## 🔮 **Future Enhancements**

### **Phase 1 Improvements**
1. **Editable LOT Numbers**: Allow custom LOT naming
2. **Auto-Calculation**: Restore HCl, Nitric acid calculations
3. **Advanced Filtering**: Date ranges, profit ranges
4. **LOT Templates**: Reusable LOT configurations

### **Phase 2 Features**
1. **LOT Batching**: Multiple batches within a LOT
2. **Resource Planning**: Material forecasting
3. **Quality Control**: QC checkpoints per LOT
4. **Advanced Analytics**: Trend analysis, forecasting

## 📚 **Development Notes**

### **Architecture Decisions**
1. **Offline-First**: Local storage with cloud sync
2. **Completion Date Analytics**: Business requirement priority
3. **Status-Driven Workflow**: Clear LOT lifecycle
4. **Backward Compatibility**: Preserve original system

### **Performance Considerations**
- **Indexed Queries**: Completion date, status indexes
- **Lazy Loading**: Large LOT lists with pagination
- **Caching Strategy**: Recent LOTs cached locally
- **Sync Optimization**: Incremental sync, conflict resolution

## 🐛 **Known Issues & Solutions**

### **Current Limitations**
1. **Manual Calculation**: Simplified P&L calculation
2. **Single User**: No multi-user LOT access
3. **Limited Reporting**: Basic analytics only

### **Troubleshooting**
- **APK Installation**: Use release APK, not debug
- **Data Not Showing**: Check LOT completion status
- **Analytics Empty**: Ensure LOTs are completed
- **Cloud Sync Issues**: Check network connectivity

---

## 📞 **Support & Maintenance**

For technical questions or feature requests, refer to this documentation and the implementation files. The LOT system is designed to be extensible and maintainable for future enhancements.

**Last Updated**: July 17, 2025
**Version**: LOT System v1.0
**Status**: Production Ready