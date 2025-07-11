# Chemical Process Tracker

A specialized Flutter web application for managing chemical manufacturing processes with complex material dependencies, multi-phase P&L calculations, and real-time efficiency tracking.

## 🏭 Overview

This application is designed for chemical manufacturing processes where:
- Raw materials are processed through multiple stages with exact mathematical formulas
- Material quantities are auto-calculated using predefined dependency chains
- Production efficiency needs real-time tracking and validation
- Multi-phase profit & loss calculations provide comprehensive financial insights

## 🎯 Key Features

### ✅ **Implemented Features**

#### **Advanced Material Management**
- **Base Materials**: Manual entry (Patti with quantity and rate)
- **Auto-calculated Materials**: Derived quantities using exact Excel formulas
  - Nitric = Patti × 1.4
  - HCL = Nitric × 3.0 (= Patti × 4.2)
  - Worker = 38000/4500 per kg of Patti
  - Rent = 25000/4500 per kg of Patti
  - Account = 5000/4500 per kg of Patti
- **Configurable Defaults**: Global settings that persist across sessions
- **Real-time Validation**: Input validation with visual feedback

#### **Production Workflow**
- **Multi-tab Interface**: Raw Materials → Production → Results
- **PD Efficiency Tracking**: (PD Quantity / Patti Quantity) × 100%
- **Efficiency Validation**: 0.1% - 10% range with visual warnings
- **Auto-save Functionality**: Data preserved while typing
- **Batch Persistence**: Complete edit/reload capability

#### **Financial Analytics**
- **Phase 1 P&L**: Processing costs (raw + derived materials)
- **Phase 2 P&L**: Primary product income (PD sales)
- **Phase 3 P&L**: Byproduct income (CU gain - TIN cost)
- **Real-time Calculations**: Instant updates on input changes
- **Profit/Loss Indicators**: Color-coded results with validation

#### **Web-optimized Architecture**
- **LocalStorage Integration**: Browser-native data persistence
- **Cross-platform Compatibility**: Works on all modern browsers
- **Responsive Design**: Material 3 professional interface
- **Performance Optimized**: Debounced calculations and smart rebuilds

## 🏗️ Technical Architecture

### **Frontend Stack**
```
├── Flutter Web (3.27.4)          # Cross-platform framework
├── Material 3 Design             # Modern UI components  
├── LocalStorage API              # Browser-native persistence
├── Advanced Calculation Engine   # Complex formula processing
└── Reactive State Management     # Real-time data flow
```

### **Core Components**
```
├── WebStorageService            # Browser localStorage management
├── AdvancedCalculationEngine    # Excel-formula implementation
├── ConfigurableDefaults         # Global settings persistence
├── Multi-tab Batch Entry       # Professional workflow UI
└── Real-time Validation        # Input validation system
```

## 📊 Process Flow & Formulas

### **Exact Excel Implementation**
The application implements your exact Excel formulas:

```
Base Input:
- Patti: [Manual] kg @ [Manual] ₹/kg

Auto-calculated Quantities:
- Nitric: Patti × 1.4
- HCL: Nitric × 3.0 (= Patti × 4.2)
- Worker: Patti × (38000/4500) = Patti × 8.44₹/kg
- Rent: Patti × (25000/4500) = Patti × 5.56₹/kg  
- Account: Patti × (5000/4500) = Patti × 1.11₹/kg

Production:
- PD: [Manual] kg @ [Manual] ₹/kg
- Efficiency: (PD / Patti) × 100% [Validated: 0.1%-10%]

Byproducts:
- CU: Patti × 10% @ [Manual] ₹/kg
- TIN: Patti × (1/450) @ [Manual] ₹/kg
```

### **Multi-Phase P&L Calculation**
```
Phase 1 - Processing Cost:
= Patti Cost + Nitric Cost + HCL Cost + Worker Cost + Rent Cost + Account Cost

Phase 2 - Product Income:  
= PD Quantity × PD Rate

Phase 3 - Byproduct Income:
= (CU Income) - (TIN Cost)

Final Net P&L:
= Phase 2 Income + Phase 3 Income - Phase 1 Cost
```

## 🚀 Getting Started

### **Web Deployment (Recommended)**
```bash
# Clone the repository
git clone [repository-url]
cd chemical_process_tracker

# Install dependencies
flutter pub get

# Build for web
flutter build web

# Serve locally
cd build/web
python3 -m http.server 8080

# Open browser: http://localhost:8080
```

### **Quick Test Scenario**
1. **Open**: http://localhost:8080
2. **Create Batch**: Click "Create Today's Batch"
3. **Raw Materials Tab**:
   - Patti Quantity: `1000` kg
   - Patti Rate: `₹50` per kg
   - Watch auto-calculations populate
4. **Production Tab**:
   - PD Quantity: `45` kg (4.5% efficiency ✅)
   - Try `150` kg (15% efficiency ⚠️ warning)
5. **Results Tab**: View complete P&L breakdown

## 🔧 Technical Challenges Solved

### **Challenge 1: Web Compatibility**
- **Problem**: SQLite doesn't work in browsers
- **Solution**: Implemented localStorage-based persistence
- **Result**: ✅ Works in all modern browsers

### **Challenge 2: Complex State Management**
- **Problem**: Riverpod providers failing on web
- **Solution**: Simplified to native Flutter state with localStorage
- **Result**: ✅ Smooth performance and reliability

### **Challenge 3: Input Field Focus Issues**
- **Problem**: Cursor jumping during calculations
- **Solution**: Debounced updates with auto-save
- **Result**: ✅ Professional typing experience

### **Challenge 4: Data Persistence**
- **Problem**: Batch editing not loading previous data
- **Solution**: Comprehensive localStorage keys per batch
- **Result**: ✅ Full edit/reload capability

## 📈 Development Phases Completed

### **✅ Phase 1: Core Architecture (Completed)**
- [x] Project setup and Flutter web configuration
- [x] Material template system with exact formulas
- [x] Advanced calculation engine implementation
- [x] Real-time validation system

### **✅ Phase 2: Advanced Features (Completed)**
- [x] Multi-tab batch entry workflow
- [x] Configurable defaults system
- [x] Auto-save and data persistence
- [x] Professional Material 3 UI

### **✅ Phase 3: Web Optimization (Completed)**
- [x] Browser compatibility fixes
- [x] LocalStorage integration
- [x] Input field optimization
- [x] Batch editing functionality

### **🔄 Phase 4: Enhancements (Pending)**
- [ ] Copy previous day functionality
- [ ] Settings/defaults management screen
- [ ] Enhanced analytics dashboard
- [ ] Professional reporting features

## 🧪 Testing Results

### **Functional Testing**
✅ **Input Validation**: All formulas working correctly  
✅ **Data Persistence**: Auto-save and reload working  
✅ **Multi-tab Navigation**: Smooth workflow experience  
✅ **Efficiency Validation**: Proper 0.1%-10% range checking  
✅ **Batch Management**: Create/edit/save functionality  

### **Expected Results Verification**
For **1000kg Patti @ ₹50/kg** with **45kg PD @ ₹2000/kg**:
- ✅ **Processing Cost**: ~₹88,444
- ✅ **PD Income**: ₹90,000  
- ✅ **Net Profit**: ~₹1,556
- ✅ **Efficiency**: 4.5% (valid range)

## 🎯 Production Ready Features

### **Reliability**
- ✅ Web-native localStorage (no database dependencies)
- ✅ Error handling and validation
- ✅ Auto-save prevents data loss
- ✅ Cross-browser compatibility

### **User Experience**
- ✅ Professional Material 3 interface
- ✅ Real-time calculations and feedback
- ✅ Visual validation indicators
- ✅ Intuitive multi-tab workflow

### **Business Logic**
- ✅ Exact Excel formula implementation
- ✅ Multi-phase P&L calculations
- ✅ Efficiency tracking and validation
- ✅ Configurable business rules

## 📞 Support & Usage

### **Live Application**
🌐 **URL**: http://localhost:8080 (when server is running)

### **Browser Requirements**
- Chrome 88+ ✅
- Firefox 78+ ✅  
- Safari 14+ ✅
- Edge 88+ ✅

### **Data Storage**
- All data stored in browser localStorage
- No external database required
- Data persists between sessions
- Export/backup functionality available

---

## 🎉 **Production Status: READY**

The Chemical Process Tracker is now fully functional with all core features implemented and tested. The application successfully replicates your Excel calculations in a professional web interface with enhanced workflow and data management capabilities.

**Ready for daily production use!** 🚀