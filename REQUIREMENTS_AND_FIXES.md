# Chemical Process Tracker - Requirements and Fixes Documentation

## Overview
This document tracks the detailed requirements and fixes for the chemical process tracker app that evolved from a batch-based to a LOT-based system.

## Critical Issues Identified (Current Build)

### 1. **CRITICAL: Calculation Engine Failure**
- **Problem**: When entering Patti price, no reflection in materials/results
- **Root Cause**: `_calculateResults()` method on line 1158-1159 uses empty `_lot.rateSnapshot` for new LOTs
- **Code Issue**: 
  ```dart
  // This fails for new LOTs where rateSnapshot is empty
  final effectiveRates = Map<String, double>.from(_lot.rateSnapshot);
  effectiveRates.addAll(_customRates);
  ```
- **Impact**: ALL calculations fail for new LOTs, making the app unusable

### 2. **CRITICAL: PD Rate Not Affecting Calculations**
- **Problem**: PD rate changes don't affect results
- **Root Cause**: Same as above - empty rate snapshot means PD rate is 0
- **Impact**: P&L calculations are completely wrong

### 3. **CRITICAL: PD Efficiency Always Shows Great**
- **Problem**: PD efficiency color coding shows green even with wrong calculations
- **Root Cause**: P&L calculation is wrong due to rate snapshot issue
- **Impact**: Misleading efficiency feedback

## Required Features Implementation History

### Phase 1: Core LOT System (Completed)
- ✅ Tab navigation with TabController
- ✅ Results tab with P&L summary, cost breakdown, and efficiency metrics
- ✅ Editable material rates with tap-to-edit functionality
- ✅ Updated Materials tab structure

### Phase 2: UI Improvements (Completed)
- ✅ Separate Patti Details and Primary Product sections
- ✅ PD Efficiency display with color coding based on PD Profit ranges
- ✅ ByProduct Materials section for CU and TIN
- ✅ Fixed edit pencil UI overflow for 3-digit amounts
- ✅ Delete LOT button for all LOT statuses

### Phase 3: Rate Management System (Implemented but Broken)
- ✅ Rate snapshot system for preserving historical rates
- ✅ LOT-specific rate changes vs default rate changes
- ❌ **BROKEN**: Rate snapshot not working for new LOTs
- ❌ **BROKEN**: Calculations fail due to empty rate snapshot

### Phase 4: Auto-Save and Data Persistence (Completed)
- ✅ Auto-save on navigation
- ✅ Data persistence across app restarts
- ✅ Save button always shows success message

## Technical Implementation Details

### Rate Management Architecture
```dart
// ProductionLot model (lib/models/production_lot.dart)
final Map<String, double> rateSnapshot; // Store rates at time of LOT creation

// Rate snapshot creation (mobile_lot_entry_screen.dart:88-101)
if (_lot.rateSnapshot.isEmpty && widget.lot == null) {
  final rateSnapshot = {
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
```

### Calculation Engine Integration
```dart
// AdvancedCalculationEngine (lib/services/calculation_engine.dart)
// Uses customRates (including rate snapshot) instead of current defaults
final effectiveRates = Map<String, double>.from(customRates ?? {});
```

## Critical Fix Required

### Problem: Rate Snapshot Not Used Correctly
Current code (BROKEN):
```dart
// Line 1158-1159 in mobile_lot_entry_screen.dart
final effectiveRates = Map<String, double>.from(_lot.rateSnapshot);
effectiveRates.addAll(_customRates);
```

### Required Fix:
```dart
// Use rate snapshot if available, otherwise use current defaults
final effectiveRates = <String, double>{};

// First add current defaults as fallback
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

// Then override with rate snapshot if available
if (_lot.rateSnapshot.isNotEmpty) {
  effectiveRates.addAll(_lot.rateSnapshot);
}

// Finally override with custom rates
effectiveRates.addAll(_customRates);
```

## Testing Checklist

### Core Functionality Tests
- [ ] **NEW LOT**: Patti price changes reflect in materials/results
- [ ] **NEW LOT**: PD quantity changes affect efficiency calculation
- [ ] **NEW LOT**: PD rate changes affect P&L calculation
- [ ] **NEW LOT**: Materials tab shows correct calculated quantities
- [ ] **NEW LOT**: Results tab shows correct P&L and cost breakdown

### Rate Management Tests
- [ ] **NEW LOT**: Uses current default rates for calculations
- [ ] **EXISTING LOT**: Uses rate snapshot for calculations
- [ ] **CUSTOM RATES**: LOT-specific rate changes override defaults
- [ ] **DEFAULT CHANGES**: Don't affect existing LOT calculations

### UI/UX Tests
- [ ] **EFFICIENCY COLOR**: Shows correct color based on actual P&L
- [ ] **SAVE BUTTON**: Always shows success message
- [ ] **DELETE BUTTON**: Available for all LOT statuses
- [ ] **AUTO-SAVE**: Data persists on navigation

## Next Steps
1. **IMMEDIATE**: Fix rate snapshot issue in `_calculateResults` method
2. **IMMEDIATE**: Test all calculation scenarios
3. **IMMEDIATE**: Build and deploy fixed APK
4. **FUTURE**: Export/share functionality
5. **FUTURE**: Offline sync and cloud integration

## File Changes Required
- `lib/screens/mobile_lot_entry_screen.dart` - Fix _calculateResults method
- `rebuild_app.sh` - Update testing checklist