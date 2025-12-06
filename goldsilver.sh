#!/bin/bash

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
GOLD_DATA_FILE="gold_prices.csv"
SILVER_DATA_FILE="silver_prices.csv"
LOG_FILE="scraper.log"

echo "[$TIMESTAMP] Starting data collection..." | tee -a $LOG_FILE

# Arrays to hold results
declare -A GOLD_DATA
declare -A SILVER_DATA

# Function to scrape prices from Kitco
scrape_kitco_prices() {
    local metal=$1
    local -n data_ref=$2  # Reference to array
    
    local url="https://www.kitco.com/charts/$metal"
    
    # Get current price
    local price=$(curl -s "$url" | \
        grep -oP '<h3[^>]*>\K[0-9,.]+' | tr -d ',' | head -1)
    
    # Get 24h high/low values
    local values=($(curl -s "$url" | \
        grep -oP '(?<=<div>)[0-9.]+(?=</div>)' | tr -d ','))
    
    # Store in array
    data_ref["price"]="$price"
    data_ref["high"]="${values[0]}"
    data_ref["low"]="${values[1]}"
    
    echo "DEBUG: Found $metal - Price: ${data_ref[price]}, High: ${data_ref[high]}, Low: ${data_ref[low]}"
}

# Scrape Gold prices
echo "=== GOLD ==="
scrape_kitco_prices "gold" GOLD_DATA
echo "Gold Price: ${GOLD_DATA[price]} USD"
echo "24h High: ${GOLD_DATA[high]}"
echo "24h Low: ${GOLD_DATA[low]}"

echo "[$TIMESTAMP] Gold Price: ${GOLD_DATA[price]} USD (High: ${GOLD_DATA[high]}, Low: ${GOLD_DATA[low]})" >> $LOG_FILE

# Scrape Silver prices
echo ""
echo "=== SILVER ==="
scrape_kitco_prices "silver" SILVER_DATA
echo "Silver Price: ${SILVER_DATA[price]} USD"
echo "24h High: ${SILVER_DATA[high]}"
echo "24h Low: ${SILVER_DATA[low]}"

echo "[$TIMESTAMP] Silver Price: ${SILVER_DATA[price]} USD (High: ${SILVER_DATA[high]}, Low: ${SILVER_DATA[low]})" >> $LOG_FILE

# Save Gold data to CSV
if [ ! -f "$GOLD_DATA_FILE" ]; then
    echo "timestamp,price,currency,high24,low24" > $GOLD_DATA_FILE
fi
echo "$TIMESTAMP,${GOLD_DATA[price]},USD,${GOLD_DATA[high]},${GOLD_DATA[low]}" >> $GOLD_DATA_FILE

# Save Silver data to CSV
if [ ! -f "$SILVER_DATA_FILE" ]; then
    echo "timestamp,price,currency,high24,low24" > $SILVER_DATA_FILE
fi
echo "$TIMESTAMP,${SILVER_DATA[price]},USD,${SILVER_DATA[high]},${SILVER_DATA[low]}" >> $SILVER_DATA_FILE

# Save to MySQL database
echo "Saving to MySQL database..."
mysql -u root -e "
USE gold_tracker;

-- Create unified metals table if not exists (without created_at and updated_at)
CREATE TABLE IF NOT EXISTS metal_prices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    metal_type ENUM('gold', 'silver') NOT NULL,
    price DECIMAL(10,4) NOT NULL,
    currency VARCHAR(10) NOT NULL DEFAULT 'USD',
    high_price DECIMAL(10,4) NOT NULL,
    low_price DECIMAL(10,4) NOT NULL,
    timestamp DATETIME NOT NULL,
    UNIQUE KEY idx_metal_timestamp (metal_type, timestamp),
    INDEX idx_timestamp (timestamp),
    INDEX idx_metal (metal_type)
);

-- Insert or update Gold data using ON DUPLICATE KEY UPDATE
INSERT INTO metal_prices (metal_type, price, currency, high_price, low_price, timestamp) 
VALUES ('gold', ${GOLD_DATA[price]}, 'USD', ${GOLD_DATA[high]}, ${GOLD_DATA[low]}, '$TIMESTAMP')
ON DUPLICATE KEY UPDATE 
    price = VALUES(price),
    high_price = VALUES(high_price),
    low_price = VALUES(low_price);

-- Insert or update Silver data using ON DUPLICATE KEY UPDATE
INSERT INTO metal_prices (metal_type, price, currency, high_price, low_price, timestamp) 
VALUES ('silver', ${SILVER_DATA[price]}, 'USD', ${SILVER_DATA[high]}, ${SILVER_DATA[low]}, '$TIMESTAMP')
ON DUPLICATE KEY UPDATE 
    price = VALUES(price),
    high_price = VALUES(high_price),
    low_price = VALUES(low_price);
" 2>> $LOG_FILE

DB_RESULT=$?

if [ $DB_RESULT -eq 0 ]; then
    echo ""
    echo "=== Recent Database Entries ==="
    mysql -u root gold_tracker -e "
    SELECT 
        metal_type as Metal,
        CONCAT('\$', FORMAT(price, 2)) as Price,
        CONCAT('\$', FORMAT(high_price, 2)) as '24h High',
        CONCAT('\$', FORMAT(low_price, 2)) as '24h Low',
        DATE_FORMAT(timestamp, '%Y-%m-%d %H:%i:%s') as Timestamp
    FROM metal_prices 
    ORDER BY timestamp DESC, metal_type 
    LIMIT 6;
    " 2>/dev/null || echo "Could not retrieve database entries"
else
    echo "Error saving to database. Check $LOG_FILE for details." >> $LOG_FILE
fi

echo "[$TIMESTAMP] Script completed" >> $LOG_FILE
