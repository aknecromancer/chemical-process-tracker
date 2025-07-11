# Database Schema Design

## Overview
This document defines the database schema for the Chemical Process Tracker application, designed to handle complex material dependencies, batch processing, and multi-phase P&L calculations.

## Core Tables

### 1. Material Templates
Defines the materials used in the manufacturing process and their relationships.

```sql
CREATE TABLE material_templates (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    category TEXT NOT NULL, -- 'raw', 'derived', 'product', 'byproduct'
    formula_type TEXT NOT NULL, -- 'manual', 'multiplier', 'custom'
    multiplier REAL, -- For formula_type = 'multiplier'
    parent_material_id TEXT, -- Reference to parent material
    unit TEXT DEFAULT 'kg', -- kg, liters, etc.
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (parent_material_id) REFERENCES material_templates(id)
);
```

### 2. Production Batches
Represents daily production batches with all materials and calculations.

```sql
CREATE TABLE production_batches (
    id TEXT PRIMARY KEY,
    date TEXT NOT NULL, -- YYYY-MM-DD format
    status TEXT DEFAULT 'draft', -- 'draft', 'completed', 'archived'
    notes TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    
    -- Calculated totals
    total_raw_materials REAL DEFAULT 0,
    total_derived_materials REAL DEFAULT 0,
    total_expenses REAL DEFAULT 0,
    total_product_income REAL DEFAULT 0,
    total_byproduct_income REAL DEFAULT 0,
    total_income REAL DEFAULT 0,
    net_pnl REAL DEFAULT 0,
    
    -- Efficiency metrics
    pd_efficiency REAL DEFAULT 0, -- (PD_Qty / Patti_Qty) * 100
    
    UNIQUE(date)
);
```

### 3. Batch Materials
Individual material entries within a production batch.

```sql
CREATE TABLE batch_materials (
    id TEXT PRIMARY KEY,
    batch_id TEXT NOT NULL,
    material_id TEXT NOT NULL,
    quantity REAL NOT NULL,
    price REAL NOT NULL,
    amount REAL NOT NULL, -- quantity * price
    is_calculated BOOLEAN DEFAULT FALSE, -- TRUE if auto-calculated
    entry_order INTEGER DEFAULT 0, -- Order of entry in workflow
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    
    FOREIGN KEY (batch_id) REFERENCES production_batches(id) ON DELETE CASCADE,
    FOREIGN KEY (material_id) REFERENCES material_templates(id)
);
```

### 4. Formula Dependencies
Tracks complex material dependencies and calculation formulas.

```sql
CREATE TABLE formula_dependencies (
    id TEXT PRIMARY KEY,
    material_id TEXT NOT NULL,
    depends_on_material_id TEXT NOT NULL,
    multiplier REAL NOT NULL,
    operation TEXT DEFAULT 'multiply', -- 'multiply', 'add', 'subtract', 'divide'
    sequence_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    
    FOREIGN KEY (material_id) REFERENCES material_templates(id),
    FOREIGN KEY (depends_on_material_id) REFERENCES material_templates(id)
);
```

### 5. Price History
Tracks historical pricing for materials to provide suggestions and trends.

```sql
CREATE TABLE price_history (
    id TEXT PRIMARY KEY,
    material_id TEXT NOT NULL,
    price REAL NOT NULL,
    date TEXT NOT NULL, -- YYYY-MM-DD
    source TEXT DEFAULT 'manual', -- 'manual', 'import', 'api'
    created_at INTEGER NOT NULL,
    
    FOREIGN KEY (material_id) REFERENCES material_templates(id)
);
```

### 6. Application Settings
Store application configuration and user preferences.

```sql
CREATE TABLE app_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    data_type TEXT DEFAULT 'string', -- 'string', 'number', 'boolean', 'json'
    updated_at INTEGER NOT NULL
);
```

## Sample Data

### Material Templates
```sql
-- Raw Material (Base)
INSERT INTO material_templates VALUES 
('patti', 'Patti', 'raw', 'manual', NULL, NULL, 'kg', 1704067200, 1704067200, TRUE);

-- Derived Materials
INSERT INTO material_templates VALUES 
('nitric', 'Nitric', 'derived', 'multiplier', 1.4, 'patti', 'kg', 1704067200, 1704067200, TRUE),
('hcl', 'HCL', 'derived', 'multiplier', 3.0, 'nitric', 'kg', 1704067200, 1704067200, TRUE);

-- Products
INSERT INTO material_templates VALUES 
('pd', 'PD', 'product', 'manual', NULL, NULL, 'kg', 1704067200, 1704067200, TRUE);

-- Byproducts
INSERT INTO material_templates VALUES 
('cu', 'CU', 'byproduct', 'manual', NULL, NULL, 'kg', 1704067200, 1704067200, TRUE),
('tin', 'TIN', 'byproduct', 'manual', NULL, NULL, 'kg', 1704067200, 1704067200, TRUE);
```

### Formula Dependencies
```sql
INSERT INTO formula_dependencies VALUES 
('dep1', 'nitric', 'patti', 1.4, 'multiply', 1, TRUE),
('dep2', 'hcl', 'nitric', 3.0, 'multiply', 2, TRUE);
```

## Indexes for Performance

```sql
-- Batch lookups by date
CREATE INDEX idx_production_batches_date ON production_batches(date);

-- Material lookups in batches
CREATE INDEX idx_batch_materials_batch_id ON batch_materials(batch_id);
CREATE INDEX idx_batch_materials_material_id ON batch_materials(material_id);

-- Formula dependency lookups
CREATE INDEX idx_formula_dependencies_material_id ON formula_dependencies(material_id);
CREATE INDEX idx_formula_dependencies_depends_on ON formula_dependencies(depends_on_material_id);

-- Price history lookups
CREATE INDEX idx_price_history_material_date ON price_history(material_id, date);
```

## Views for Complex Queries

### Batch Summary View
```sql
CREATE VIEW batch_summary AS
SELECT 
    pb.id,
    pb.date,
    pb.status,
    pb.total_expenses,
    pb.total_income,
    pb.net_pnl,
    pb.pd_efficiency,
    COUNT(bm.id) as material_count
FROM production_batches pb
LEFT JOIN batch_materials bm ON pb.id = bm.batch_id
GROUP BY pb.id, pb.date, pb.status, pb.total_expenses, pb.total_income, pb.net_pnl, pb.pd_efficiency;
```

### Material Dependency Tree View
```sql
CREATE VIEW material_dependency_tree AS
WITH RECURSIVE dependency_tree AS (
    -- Base case: materials with no dependencies
    SELECT 
        id, name, category, formula_type, 
        multiplier, parent_material_id, 
        0 as level, 
        name as path
    FROM material_templates 
    WHERE parent_material_id IS NULL
    
    UNION ALL
    
    -- Recursive case: materials with dependencies
    SELECT 
        mt.id, mt.name, mt.category, mt.formula_type,
        mt.multiplier, mt.parent_material_id,
        dt.level + 1 as level,
        dt.path || ' -> ' || mt.name as path
    FROM material_templates mt
    JOIN dependency_tree dt ON mt.parent_material_id = dt.id
)
SELECT * FROM dependency_tree ORDER BY level, name;
```

## Data Relationships

```
material_templates (1) -> (N) batch_materials
material_templates (1) -> (N) formula_dependencies
material_templates (1) -> (N) price_history
production_batches (1) -> (N) batch_materials
material_templates (1) -> (N) material_templates (self-referencing)
```

## Calculation Logic

### Phase 1: Raw Material Expenses
```sql
SELECT SUM(amount) as phase1_expenses
FROM batch_materials bm
JOIN material_templates mt ON bm.material_id = mt.id
WHERE bm.batch_id = ? AND mt.category IN ('raw', 'derived');
```

### Phase 2: Product Income & Efficiency
```sql
SELECT 
    SUM(CASE WHEN mt.category = 'product' THEN bm.amount ELSE 0 END) as product_income,
    (MAX(CASE WHEN mt.name = 'PD' THEN bm.quantity ELSE 0 END) / 
     MAX(CASE WHEN mt.name = 'Patti' THEN bm.quantity ELSE 0 END) * 100) as pd_efficiency
FROM batch_materials bm
JOIN material_templates mt ON bm.material_id = mt.id
WHERE bm.batch_id = ?;
```

### Phase 3: Final P&L
```sql
SELECT 
    SUM(CASE WHEN mt.category IN ('product', 'byproduct') THEN bm.amount ELSE 0 END) as total_income,
    SUM(CASE WHEN mt.category IN ('raw', 'derived') THEN bm.amount ELSE 0 END) as total_expenses,
    SUM(CASE WHEN mt.category IN ('product', 'byproduct') THEN bm.amount ELSE -bm.amount END) as net_pnl
FROM batch_materials bm
JOIN material_templates mt ON bm.material_id = mt.id
WHERE bm.batch_id = ?;
```

This schema provides a flexible foundation for complex material dependencies, efficient batch processing, and comprehensive financial tracking while maintaining data integrity and performance.