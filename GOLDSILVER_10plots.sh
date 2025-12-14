#!/bin/bash
# GOLDSILVER_10plots.sh - Generate 2 graphs for gold and silver
# First: Draw only 2 graphs (daily highest prices)

echo "========================================"
echo "   Gold & Silver Graph Generator"
echo "========================================"
echo ""

# Create directories
mkdir -p graphs
mkdir -p data

echo "Step 1: Extracting data from database..."

# Extract daily highest price for GOLD
sudo mysql -D gold_tracker -e "
SELECT
    DATE(timestamp) as date,
    MAX(high_price) as daily_high
FROM metal_prices
WHERE metal_type = 'gold'
GROUP BY DATE(timestamp)
ORDER BY date;
" | tail -n +2 > data/gold_daily_high.txt

# Extract daily highest price for SILVER
sudo mysql -D gold_tracker -e "
SELECT
    DATE(timestamp) as date,
    MAX(high_price) as daily_high
FROM metal_prices
WHERE metal_type = 'silver'
GROUP BY DATE(timestamp)
ORDER BY date;
" | tail -n +2 > data/silver_daily_high.txt

echo "Data extracted to:"
echo "  data/gold_daily_high.txt"
echo "  data/silver_daily_high.txt"
echo ""

echo "Step 2: Generating graphs with gnuplot..."

# Check if gnuplot is installed
if ! command -v gnuplot &> /dev/null; then
    echo "Error: gnuplot is not installed!"
    echo "Install it with: sudo apt-get install gnuplot"
    exit 1
fi

# ====================
# GRAPH 1: GOLD
# ====================
echo "Creating Gold graph..."
gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/gold_daily_high.png'

set title 'Gold - Daily Highest Price (24-hour High)' font 'Arial,14'
set xlabel 'Date' font 'Arial,11'
set ylabel 'Highest Price (USD)' font 'Arial,11'

# Set time format for x-axis
set xdata time
set timefmt "%Y-%m-%d"
set format x "%b %d"
set xtics rotate by 45 right

# Set grid
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

# Set colors for gold
set style line 1 lc rgb '#FFD700' lt 1 lw 3 pt 7 ps 1.2

# Plot the data
plot 'data/gold_daily_high.txt' using 1:2 with linespoints ls 1 title 'Gold Daily High'
EOF

# ====================
# GRAPH 2: SILVER
# ====================
echo "Creating Silver graph..."
gnuplot << EOF
set terminal png size 1200,600 enhanced font 'Arial,10'
set output 'graphs/silver_daily_high.png'

set title 'Silver - Daily Highest Price (24-hour High)' font 'Arial,14'
set xlabel 'Date' font 'Arial,11'
set ylabel 'Highest Price (USD)' font 'Arial,11'

# Set time format for x-axis
set xdata time
set timefmt "%Y-%m-%d"
set format x "%b %d"
set xtics rotate by 45 right

# Set grid
set grid
set grid lt 1 lc rgb '#dddddd' lw 1

# Set colors for silver
set style line 1 lc rgb '#C0C0C0' lt 1 lw 3 pt 5 ps 1.2

# Plot the data
plot 'data/silver_daily_high.txt' using 1:2 with linespoints ls 1 title 'Silver Daily High'
EOF

echo ""
echo "Step 3: Done!"
echo ""
echo "Generated 2 graphs:"
echo "  1. graphs/gold_daily_high.png"
echo "  2. graphs/silver_daily_high.png"
echo ""
echo "To view the graphs:"
echo "  display graphs/gold_daily_high.png"
echo "  display graphs/silver_daily_high.png"
echo ""
echo "Or open with:"
echo "  xdg-open graphs/gold_daily_high.png"
echo "  xdg-open graphs/silver_daily_high.png"
echo ""
