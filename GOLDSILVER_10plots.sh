#!/bin/bash
# GOLDSILVER_10plots.sh - Generate 10 graphs for gold and silver analysis
# Extended version with more detailed visualizations

echo "========================================"
echo "   Gold & Silver Graph Generator - 10 Graphs"
echo "========================================"
echo ""

# Create directories
mkdir -p graphs
mkdir -p data

echo "Step 1: Extracting data from database..."

# ====================
# DAILY DATA EXTRACTION
# ====================

# Extract daily highest price for GOLD
sudo mysql -D gold_tracker -e "
SELECT
    DATE(timestamp) as date,
    MAX(high_price) as daily_high,
    MIN(low_price) as daily_low,
    AVG(price) as daily_avg_price
FROM metal_prices
WHERE metal_type = 'gold'
GROUP BY DATE(timestamp)
ORDER BY date;
" | tail -n +2 > data/gold_daily_summary.txt

# Extract daily highest price for SILVER
sudo mysql -D gold_tracker -e "
SELECT
    DATE(timestamp) as date,
    MAX(high_price) as daily_high,
    MIN(low_price) as daily_low,
    AVG(price) as daily_avg_price
FROM metal_prices
WHERE metal_type = 'silver'
GROUP BY DATE(timestamp)
ORDER BY date;
" | tail -n +2 > data/silver_daily_summary.txt

# ====================
# TIME SERIES DATA EXTRACTION - CORRECTED FORMAT
# ====================

echo "Extracting time series data with proper format..."

# CORRECTED: Extract gold prices with SIMPLER formatting
sudo mysql -D gold_tracker -e "
SELECT 
    timestamp,
    price
FROM metal_prices 
WHERE metal_type = 'gold'
ORDER BY timestamp;
" | tail -n +2 > data/gold_time_series_correct.txt

# CORRECTED: Extract silver prices with SIMPLER formatting  
sudo mysql -D gold_tracker -e "
SELECT 
    timestamp,
    price
FROM metal_prices 
WHERE metal_type = 'silver'
ORDER BY timestamp;
" | tail -n +2 > data/silver_time_series_correct.txt

# ====================
# 12PM NOON PRICES EXTRACTION
# ====================

echo "Extracting 12PM noon prices..."

# Extract gold noon prices - FIXED
sudo mysql -D gold_tracker -e "
SELECT 
    CONCAT(DATE(timestamp), ' 12:00:00') as timestamp,
    CAST(price AS DECIMAL(10,2)) AS price
FROM (
    SELECT 
        DATE(timestamp) as date,
        timestamp,
        price,
        ROW_NUMBER() OVER (
            PARTITION BY DATE(timestamp) 
            ORDER BY ABS(TIME_TO_SEC(TIMEDIFF(TIME(timestamp), '12:00:00')))
        ) as time_rank
    FROM metal_prices
    WHERE metal_type = 'gold'
    AND timestamp >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
) ranked
WHERE time_rank = 1
ORDER BY timestamp;
" | tail -n +2 > data/gold_noon_prices_fixed.txt

# Extract silver noon prices
sudo mysql -D gold_tracker -e "
SELECT 
    CONCAT(DATE(timestamp), ' 12:00:00') as timestamp,
    price
FROM (
    SELECT 
        DATE(timestamp) as date,
        timestamp,
        price,
        ROW_NUMBER() OVER (
            PARTITION BY DATE(timestamp) 
            ORDER BY ABS(TIME_TO_SEC(TIMEDIFF(TIME(timestamp), '12:00:00')))
        ) as time_rank
    FROM metal_prices
    WHERE metal_type = 'silver'
    AND timestamp >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
) ranked
WHERE time_rank = 1
ORDER BY timestamp;
" | tail -n +2 > data/silver_noon_prices_fixed.txt

# ====================
# SPECIFIC TIME RANGE (ID 91-138)
# ====================

# Extract specific range for gold (ID 91-138, corresponding to Dec 9, 2025)
sudo mysql -D gold_tracker -e "
SELECT
    timestamp,
    price,
    high_price,
    low_price
FROM metal_prices
WHERE metal_type = 'gold'
  AND id BETWEEN 91 AND 138
ORDER BY timestamp;
" | tail -n +2 > data/gold_dec9_hourly.txt

# Extract specific range for silver (ID 91-138, corresponding to Dec 9, 2025)
sudo mysql -D gold_tracker -e "
SELECT
    timestamp,
    price,
    high_price,
    low_price
FROM metal_prices
WHERE metal_type = 'silver'
  AND id BETWEEN 91 AND 138
ORDER BY timestamp;
" | tail -n +2 > data/silver_dec9_hourly.txt

# ====================
# PERCENTAGE CHANGE CALCULATION
# ====================

# Calculate percentage change for gold
sudo mysql -D gold_tracker -e "
SELECT
    t1.timestamp,
    t1.price,
    ROUND(((t1.price - t2.price) / t2.price) * 100, 2) as pct_change
FROM metal_prices t1
JOIN metal_prices t2 ON t1.id = t2.id + 2
WHERE t1.metal_type = 'gold'
ORDER BY t1.timestamp;
" | tail -n +2 > data/gold_pct_change.txt

# Calculate percentage change for silver
sudo mysql -D gold_tracker -e "
SELECT
    t1.timestamp,
    t1.price,
    ROUND(((t1.price - t2.price) / t2.price) * 100, 2) as pct_change
FROM metal_prices t1
JOIN metal_prices t2 ON t1.id = t2.id + 2
WHERE t1.metal_type = 'silver'
ORDER BY t1.timestamp;
" | tail -n +2 > data/silver_pct_change.txt

echo "Data extracted to data/ directory"
echo ""

echo "Step 2: Generating 10 graphs with gnuplot..."

# Check if gnuplot is installed
if ! command -v gnuplot &> /dev/null; then
    echo "Error: gnuplot is not installed!"
    echo "Install it with: sudo apt-get install gnuplot"
    exit 1
fi

# ====================
# GRAPH 1: GOLD DAILY HIGH
# ====================
echo "1. Creating Gold Daily High graph..."
gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/01_gold_daily_high.png'

set title 'Gold - Daily Highest Price (24-hour High)' font 'Arial,14'
set xlabel 'Date' font 'Arial,11'
set ylabel 'Highest Price (USD)' font 'Arial,11'

set xdata time
set timefmt "%Y-%m-%d"
set format x "%b %d"
set xtics rotate by 45 right
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

set style line 1 lc rgb '#FFD700' lt 1 lw 3 pt 7 ps 1.2
plot 'data/gold_daily_summary.txt' using 1:2 with linespoints ls 1 title 'Gold Daily High'
EOF

# ====================
# GRAPH 2: SILVER DAILY HIGH
# ====================
echo "2. Creating Silver Daily High graph..."
gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/02_silver_daily_high.png'

set title 'Silver - Daily Highest Price (24-hour High)' font 'Arial,14'
set xlabel 'Date' font 'Arial,11'
set ylabel 'Highest Price (USD)' font 'Arial,11'

set xdata time
set timefmt "%Y-%m-%d"
set format x "%b %d"
set xtics rotate by 45 right
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

set style line 1 lc rgb '#C0C0C0' lt 1 lw 3 pt 5 ps 1.2
plot 'data/silver_daily_summary.txt' using 1:2 with linespoints ls 1 title 'Silver Daily High'
EOF

# ====================
# GRAPH 3: GOLD 12PM NOON PRICES (PAST WEEK) - FIXED
# ====================
echo "3. Creating Gold 12PM Noon Prices (Past Week) graph..."

# Debug: Show what data we have
echo "Gold noon prices data sample:"
head -5 data/gold_noon_prices_fixed.txt
echo ""

gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/03_gold_12pm_weekly.png'

set title 'Gold - 12PM Noon Prices (Past 7 Days)' font 'Arial,14'
set xlabel 'Date' font 'Arial,11'
set ylabel 'Price at Noon (USD)' font 'Arial,11'

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%a\n%b %d"
set xtics rotate by 45 right
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

# Manually set y-axis range for gold (based on your data 4197-4211)
set yrange [4190:4220]
set ytics 4190,5,4220
set format y "%.0f"

# Use bars for better visibility
set style fill solid 0.7
set boxwidth 0.6 relative
set style line 1 lc rgb '#FFD700'

# Simple check if file exists and has data
plot 'data/gold_noon_prices_fixed.txt' using 1:3 with boxes ls 1 title 'Gold Price at Noon', \
     '' using 1:2:2 with labels offset 0,1 font ',10' notitle
EOF

# ====================
# GRAPH 4: SILVER 12PM NOON PRICES (PAST WEEK) - FIXED
# ====================
echo "4. Creating Silver 12PM Noon Prices (Past Week) graph..."

# Debug: Show what data we have
echo "Silver noon prices data sample:"
head -5 data/silver_noon_prices_fixed.txt
echo ""

gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/04_silver_12pm_weekly.png'

set title 'Silver - 12PM Noon Prices (Past 7 Days)' font 'Arial,14'
set xlabel 'Date' font 'Arial,11'
set ylabel 'Price at Noon (USD)' font 'Arial,11'

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%a\n%b %d"
set xtics rotate by 45 right
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

# Manually set y-axis range for silver (based on your data 58.27-60.88)
set yrange [58:61]
set ytics 58,0.5,61
set format y "%.2f"

# Use bars for better visibility
set style fill solid 0.7
set boxwidth 0.6 relative
set style line 1 lc rgb '#C0C0C0'

# Simple check if file exists and has data
plot 'data/silver_noon_prices_fixed.txt' using 1:2 with boxes ls 1 title 'Silver Price at Noon', \
     '' using 1:2:2 with labels offset 0,1 font ',10' notitle
EOF

# ====================
# GRAPH 5: GOLD DAILY LOW
# ====================
echo "5. Creating Gold Daily Low graph..."
gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/05_gold_daily_low.png'

set title 'Gold - Daily Lowest Price (24-hour Low)' font 'Arial,14'
set xlabel 'Date' font 'Arial,11'
set ylabel 'Lowest Price (USD)' font 'Arial,11'

set xdata time
set timefmt "%Y-%m-%d"
set format x "%b %d"
set xtics rotate by 45 right
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

set style line 1 lc rgb '#B8860B' lt 1 lw 3 pt 7 ps 1.2
plot 'data/gold_daily_summary.txt' using 1:3 with linespoints ls 1 title 'Gold Daily Low'
EOF

# ====================
# GRAPH 6: SILVER DAILY LOW
# ====================
echo "6. Creating Silver Daily Low graph..."
gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/06_silver_daily_low.png'

set title 'Silver - Daily Lowest Price (24-hour Low)' font 'Arial,14'
set xlabel 'Date' font 'Arial,11'
set ylabel 'Lowest Price (USD)' font 'Arial,11'

set xdata time
set timefmt "%Y-%m-%d"
set format x "%b %d"
set xtics rotate by 45 right
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

set style line 1 lc rgb '#A0A0A0' lt 1 lw 3 pt 5 ps 1.2
plot 'data/silver_daily_summary.txt' using 1:3 with linespoints ls 1 title 'Silver Daily Low'
EOF

# ====================
# GRAPH 7: GOLD HOURLY - DEC 9, 2025
# ====================
echo "7. Creating Gold Hourly (Dec 9, 2025) graph..."

gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/07_gold_dec9_hourly.png'

set title 'Gold - Prices on December 9, 2025' font 'Arial,14'
set xlabel 'Time' font 'Arial,11'
set ylabel 'Price (USD)' font 'Arial,11'

# Try with time formatting
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M"
set xtics rotate by 45 right
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

set style line 1 lc rgb '#FFD700' lt 1 lw 2 pt 7 ps 0.8

# Plot with time
plot 'data/gold_dec9_hourly.txt' using 1:2 with linespoints ls 1 title 'Gold Price'
EOF

# ====================
# GRAPH 8: SILVER HOURLY - DEC 9, 2025
# ====================
echo "8. Creating Silver Hourly (Dec 9, 2025) graph..."

gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/08_silver_dec9_hourly.png'

set title 'Silver - Prices on December 9, 2025' font 'Arial,14'
set xlabel 'Time' font 'Arial,11'
set ylabel 'Price (USD)' font 'Arial,11'

# Try with time formatting
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M"
set xtics rotate by 45 right
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

set style line 1 lc rgb '#C0C0C0' lt 1 lw 2 pt 5 ps 0.8

# Plot with time
plot 'data/silver_dec9_hourly.txt' using 1:2 with linespoints ls 1 title 'Silver Price'
EOF

# ====================
# GRAPH 9: GOLD PERCENTAGE CHANGE
# ====================
echo "9. Creating Gold Percentage Change graph..."
gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/09_gold_percentage_change.png'

set title 'Gold - Percentage Change Over Time' font 'Arial,14'
set xlabel 'Date & Time' font 'Arial,11'
set ylabel 'Percentage Change (%)' font 'Arial,11'

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%b %d\n%H:%M"
set xtics rotate by 45 right
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

set style line 1 lc rgb '#FF4500' lt 1 lw 2
plot 'data/gold_pct_change.txt' using 1:3 with lines ls 1 title 'Gold % Change'
EOF

# ====================
# GRAPH 10: SILVER PERCENTAGE CHANGE
# ====================
echo "10. Creating Silver Percentage Change graph..."
gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/10_silver_percentage_change.png'

set title 'Silver - Percentage Change Over Time' font 'Arial,14'
set xlabel 'Date & Time' font 'Arial,11'
set ylabel 'Percentage Change (%)' font 'Arial,11'

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%b %d\n%H:%M"
set xtics rotate by 45 right
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

set style line 1 lc rgb '#4682B4' lt 1 lw 2
plot 'data/silver_pct_change.txt' using 1:3 with lines ls 1 title 'Silver % Change'
EOF

echo ""
echo "Step 3: Done!"
echo ""
echo "========================================"
echo "Generated 10 graphs:"
echo "========================================"
echo "1.  graphs/01_gold_daily_high.png"
echo "2.  graphs/02_silver_daily_high.png"
echo "3.  graphs/03_gold_12pm_weekly.png"
echo "4.  graphs/04_silver_12pm_weekly.png"
echo "5.  graphs/05_gold_daily_low.png"
echo "6.  graphs/06_silver_daily_low.png"
echo "7.  graphs/07_gold_dec9_hourly.png"
echo "8.  graphs/08_silver_dec9_hourly.png"
echo "9.  graphs/09_gold_percentage_change.png"
echo "10. graphs/10_silver_percentage_change.png"
echo ""
echo "To view individual graphs:"
echo "  display graphs/01_gold_daily_high.png"
echo "  xdg-open graphs/01_gold_daily_high.png"
echo ""
echo "Data files available in: data/"
echo "  - gold_daily_summary.txt"
echo "  - silver_daily_summary.txt"
echo "  - gold_time_series_correct.txt"
echo "  - silver_time_series_correct.txt"
echo "  - gold_noon_prices_fixed.txt"
echo "  - silver_noon_prices_fixed.txt"
echo "  - gold_dec9_hourly.txt"
echo "  - silver_dec9_hourly.txt"
echo "  - gold_pct_change.txt"
echo "  - silver_pct_change.txt"
echo ""
