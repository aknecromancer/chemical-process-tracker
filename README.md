# Chemical Process Tracker

A specialized Flutter application for managing chemical manufacturing processes with complex material dependencies, multi-phase P&L calculations, and efficiency tracking.

## 🏭 Overview

This application is designed for chemical manufacturing processes where:
- Raw materials are processed through multiple stages
- Material quantities are calculated using predefined formulas
- Production efficiency needs to be tracked and optimized
- Multi-phase profit & loss calculations are required

## 🎯 Key Features

### Material Management
- **Base Materials**: Manual entry (e.g., Patti)
- **Derived Materials**: Auto-calculated quantities based on formulas (e.g., Nitric = Patti × 1.4)
- **Complex Dependencies**: Support for multi-level material chains
- **Daily Price Updates**: Manual price entry for market-variable materials

### Production Tracking
- **Daily Batch Processing**: Streamlined workflow for daily production entries
- **Real-time Calculations**: Automatic quantity and amount calculations
- **Validation Rules**: Prevent impossible values and inconsistencies
- **Historical Tracking**: Complete production history with trends

### Financial Analytics
- **Phase 1 P&L**: Raw material expenses (Patti, Nitric, HCL, etc.)
- **Phase 2 P&L**: Primary product income (PD) with efficiency tracking
- **Phase 3 P&L**: Byproduct income (CU, TIN) and final profitability
- **Efficiency Metrics**: PD percentage, material utilization, waste tracking

## 🏗️ Architecture

### Core Components
```
├── Material Template Engine    # Define materials and formulas
├── Batch Processing System     # Daily production workflows
├── Multi-Phase P&L Calculator  # Complex financial calculations
├── Analytics Dashboard         # Efficiency and profitability insights
└── Reporting System           # Export and analysis tools
```

### Technical Stack
- **Frontend**: Flutter with Material 3 design
- **State Management**: Riverpod for complex dependencies
- **Database**: SQLite with relational design
- **Calculations**: Real-time reactive calculations
- **Reporting**: Charts, PDF generation, data export

## 📊 Process Flow

### Daily Workflow
1. **Create Daily Batch**: Select date and initialize production batch
2. **Enter Base Material**: Input Patti quantity and current price
3. **Auto-Calculate Derived**: System calculates Nitric, HCL quantities
4. **Manual Price Entry**: Enter current market prices for derived materials
5. **Primary Product Entry**: Input PD quantity and price (income)
6. **Byproduct Entry**: Input CU and TIN quantities and prices
7. **Review P&L**: View multi-phase calculations and efficiency metrics

### Example Calculation Chain
```
Patti: 200 kg @ ₹271/kg = ₹54,200 (Expense)
├── Nitric: 280 kg (200 × 1.4) @ market price (Expense)
└── HCL: 840 kg (280 × 3) @ market price (Expense)

PD: Manual entry @ market price (Income)
├── Efficiency: (PD_Qty / Patti_Qty) × 100%
└── Phase 2 P&L: PD Income - Phase 1 Expenses

CU: Manual entry @ market price (Income)
TIN: Manual entry @ market price (Income)
Final P&L: All Income - All Expenses
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code

### Installation
```bash
# Clone the repository
git clone https://github.com/aknecromancer/chemical-process-tracker.git

# Navigate to project directory
cd chemical-process-tracker

# Install dependencies
flutter pub get

# Run the application
flutter run
```

### Development Setup
```bash
# Run in development mode
flutter run --debug

# Build for web
flutter build web

# Run tests
flutter test
```

## 📱 Screenshots

*Screenshots will be added as the application is developed*

## 🤝 Contributing

This is a specialized application for a specific manufacturing process. If you have similar requirements or suggestions for improvements, please open an issue or submit a pull request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔄 Development Status

- [x] Project setup and architecture planning
- [ ] Material template system
- [ ] Batch processing workflow
- [ ] Multi-phase P&L calculations
- [ ] Analytics dashboard
- [ ] Reporting system
- [ ] Mobile optimization
- [ ] Advanced features (inventory, forecasting)

## 📞 Support

For questions or support related to this application, please open an issue in the GitHub repository.

---

*Built with Flutter for efficient chemical process management and profitability tracking.*