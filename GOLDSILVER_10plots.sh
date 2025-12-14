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
# TIME SERIES DATA (ALL RECORDS)
# ====================

# Extract all gold prices over time
sudo mysql -D gold_tracker -e "
SELECT
    timestamp,
    price,
    high_price,
    low_price
FROM metal_prices
WHERE metal_type = 'gold'
ORDER BY timestamp;
" | tail -n +2 > data/gold_time_series.txt

# Extract all silver prices over time
sudo mysql -D gold_tracker -e "
SELECT
    timestamp,
    price,
    high_price,
    low_price
FROM metal_prices
WHERE metal_type = 'silver'
ORDER BY timestamp;
" | tail -n +2 > data/silver_time_series.txt

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
# GRAPH 3: GOLD CURRENT PRICE OVER TIME
# ====================
echo "3. Creating Gold Current Price Over Time graph..."
gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/03_gold_current_price.png'

set title 'Gold - Current Price Over Time' font 'Arial,14'
set xlabel 'Date & Time' font 'Arial,11'
set ylabel 'Price (USD)' font 'Arial,11'

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%b %d\n%H:%M"
set xtics rotate by 45 right
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

set style line 1 lc rgb '#FFD700' lt 1 lw 2
plot 'data/gold_time_series.txt' using 1:2 with lines ls 1 title 'Gold Price'
EOF

# ====================
# GRAPH 4: SILVER CURRENT PRICE OVER TIME
# ====================
echo "4. Creating Silver Current Price Over Time graph..."
gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/04_silver_current_price.png'

set title 'Silver - Current Price Over Time' font 'Arial,14'
set xlabel 'Date & Time' font 'Arial,11'
set ylabel 'Price (USD)' font 'Arial,11'

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%b %d\n%H:%M"
set xtics rotate by 45 right
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

set style line 1 lc rgb '#C0C0C0' lt 1 lw 2
plot 'data/silver_time_series.txt' using 1:2 with lines ls 1 title 'Silver Price'
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

set title 'Gold - Hourly Prices (Dec 9, 2025)' font 'Arial,14'
set xlabel 'Time' font 'Arial,11'
set ylabel 'Price (USD)' font 'Arial,11'

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M"
set xtics rotate by 45 right
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

set style line 1 lc rgb '#FFD700' lt 1 lw 3 pt 7 ps 1.2
set style line 2 lc rgb '#FF8C00' lt 1 lw 2 dt 2
set style line 3 lc rgb '#B8860B' lt 1 lw 2 dt 2

plot 'data/gold_dec9_hourly.txt' using 1:2 with linespoints ls 1 title 'Current Price', \
     '' using 1:3 with lines ls 2 title 'High Price', \
     '' using 1:4 with lines ls 3 title 'Low Price'
EOF

# ====================
# GRAPH 8: SILVER HOURLY - DEC 9, 2025
# ====================
echo "8. Creating Silver Hourly (Dec 9, 2025) graph..."
gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/08_silver_dec9_hourly.png'

set title 'Silver - Hourly Prices (Dec 9, 2025)' font 'Arial,14'
set xlabel 'Time' font 'Arial,11'
set ylabel 'Price (USD)' font 'Arial,11'

set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
set format x "%H:%M"
set xtics rotate by 45 right
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

set style line 1 lc rgb '#C0C0C0' lt 1 lw 3 pt 5 ps 1.2
set style line 2 lc rgb '#808080' lt 1 lw 2 dt 2
set style line 3 lc rgb '#606060' lt 1 lw 2 dt 2

plot 'data/silver_dec9_hourly.txt' using 1:2 with linespoints ls 1 title 'Current Price', \
     '' using 1:3 with lines ls 2 title 'High Price', \
     '' using 1:4 with lines ls 3 title 'Low Price'
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
echo "Step 3: Creating HTML report..."
cat > graphs/report.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Gold & Silver Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #333; text-align: center; }
        h2 { color: #666; border-bottom: 2px solid #ddd; padding-bottom: 10px; }
        .graph-container {
            background-color: white;
            padding: 20px;
            margin: 20px 0;
            border-radius: 10px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .graph-row { display: flex; flex-wrap: wrap; justify-content: space-between; }
        .graph-item { width: 48%; margin-bottom: 20px; }
        img { max-width: 100%; height: auto; border: 1px solid #ddd; }
        .description { color: #666; font-size: 14px; margin-top: 10px; }
    </style>
</head>
<body>
    <h1>Gold & Silver Analysis Report</h1>
    <p>Generated on: $(date)</p>

    <h2>Daily Analysis</h2>
    <div class="graph-row">
        <div class="graph-item">
            <div class="graph-container">
                <h3>1. Gold Daily High</h3>
                <img src="01_gold_daily_high.png" alt="Gold Daily High">
                <p class="description">Daily highest price (24-hour high) for gold</p>
            </div>
        </div>
        <div class="graph-item">
            <div class="graph-container">
                <h3>2. Silver Daily High</h3>
                <img src="02_silver_daily_high.png" alt="Silver Daily High">
                <p class="description">Daily highest price (24-hour high) for silver</p>
            </div>
        </div>
        <div class="graph-item">
            <div class="graph-container">
                <h3>5. Gold Daily Low</h3>
                <img src="05_gold_daily_low.png" alt="Gold Daily Low">
                <p class="description">Daily lowest price (24-hour low) for gold</p>
            </div>
        </div>
        <div class="graph-item">
            <div class="graph-container">
                <h3>6. Silver Daily Low</h3>
                <img src="06_silver_daily_low.png" alt="Silver Daily Low">
                <p class="description">Daily lowest price (24-hour low) for silver</p>
            </div>
        </div>
    </div>

    <h2>Time Series Analysis</h2>
    <div class="graph-row">
        <div class="graph-item">
            <div class="graph-container">
                <h3>3. Gold Current Price Over Time</h3>
                <img src="03_gold_current_price.png" alt="Gold Current Price">
                <p class="description">Gold price fluctuations over the entire period</p>
            </div>
        </div>
        <div class="graph-item">
            <div class="graph-container">
                <h3>4. Silver Current Price Over Time</h3>
                <img src="04_silver_current_price.png" alt="Silver Current Price">
                <p class="description">Silver price fluctuations over the entire period</p>
            </div>
        </div>
    </div>

    <h2>Detailed Hourly Analysis (Dec 9, 2025)</h2>
    <div class="graph-row">
        <div class="graph-item">
            <div class="graph-container">
                <h3>7. Gold Hourly Prices</h3>
                <img src="07_gold_dec9_hourly.png" alt="Gold Hourly Dec 9">
                <p class="description">Hourly gold prices on December 9, 2025 with high/low ranges</p>
            </div>
        </div>
        <div class="graph-item">
            <div class="graph-container">
                <h3>8. Silver Hourly Prices</h3>
                <img src="08_silver_dec9_hourly.png" alt="Silver Hourly Dec 9">
                <p class="description">Hourly silver prices on December 9, 2025 with high/low ranges</p>
            </div>
        </div>
    </div>

    <h2>Percentage Change Analysis</h2>
    <div class="graph-row">
        <div class="graph-item">
            <div class="graph-container">
                <h3>9. Gold Percentage Change</h3>
                <img src="09_gold_percentage_change.png" alt="Gold Percentage Change">
                <p class="description">Percentage change in gold prices over time</p>
            </div>
        </div>
        <div class="graph-item">
            <div class="graph-container">
                <h3>10. Silver Percentage Change</h3>
                <img src="10_silver_percentage_change.png" alt="Silver Percentage Change">
                <p class="description">Percentage change in silver prices over time</p>
            </div>
        </div>
    </div>
</body>
</html>
EOF

echo ""
echo "Step 4: Done!"
echo ""
echo "========================================"
echo "Generated 10 graphs:"
echo "========================================"
echo "1.  graphs/01_gold_daily_high.png"
echo "2.  graphs/02_silver_daily_high.png"
echo "3.  graphs/03_gold_current_price.png"
echo "4.  graphs/04_silver_current_price.png"
echo "5.  graphs/05_gold_daily_low.png"
echo "6.  graphs/06_silver_daily_low.png"
echo "7.  graphs/07_gold_dec9_hourly.png"
echo "8.  graphs/08_silver_dec9_hourly.png"
echo "9.  graphs/09_gold_percentage_change.png"
echo "10. graphs/10_silver_percentage_change.png"
echo ""
echo "Also created HTML report: graphs/report.html"
echo ""
echo "To view all graphs in a web browser:"
echo "  cd graphs && python3 -m http.server 8000"
echo "Then open: http://localhost:8000/report.html"
echo ""
echo "To view individual graphs:"
echo "  display graphs/01_gold_daily_high.png"
echo "  xdg-open graphs/01_gold_daily_high.png"
echo ""
echo "Data files available in: data/"
echo "  - gold_daily_summary.txt"
echo "  - silver_daily_summary.txt"
echo "  - gold_time_series.txt"
echo "  - silver_time_series.txt"
echo "  - gold_dec9_hourly.txt"
echo "  - silver_dec9_hourly.txt"
echo "  - gold_pct_change.txt"
echo "  - silver_pct_change.txt"
echo ""
