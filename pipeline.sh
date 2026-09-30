#!/usr/bin/env bash
#
# pipeline.sh: Download a year of NOAA Storm Events and convert it to GeoParquet.
#
# Usage:   ./pipeline.sh [YEAR]
# Example: ./pipeline.sh 2025
#
# Requires: bash, curl, gunzip, ogr2ogr (GDAL >= 3.5 with the Parquet driver)

set -euo pipefail

# -----------------------------------------------------------------------------
# Config
# -----------------------------------------------------------------------------

# Year to pull. Override by passing it as the first argument.
YEAR="${1:-2025}"

# NOAA publishes each year with a creation date in the file name (c<YYYYMMDD>).
# Update CREATED_DATE if NOAA republishes a year or the download returns a 404.
CREATED_DATE="20260819"

BASE_URL="https://www.ncei.noaa.gov/pub/data/swdi/stormevents/csvfiles"
FILE_NAME="StormEvents_details-ftp_v1.0_d${YEAR}_c${CREATED_DATE}.csv.gz"
URL="${BASE_URL}/${FILE_NAME}"

RAW_DIR="data/raw"
PROCESSED_DIR="data/processed"
RAW_GZ="${RAW_DIR}/${FILE_NAME}"
RAW_CSV="${RAW_DIR}/${FILE_NAME%.gz}"
OUT_PARQUET="${PROCESSED_DIR}/storms_${YEAR}.parquet"

# -----------------------------------------------------------------------------
# Step 1: Set up directories
# -----------------------------------------------------------------------------

echo "[1/4] Setting up directories"
mkdir -p "${RAW_DIR}" "${PROCESSED_DIR}"

# -----------------------------------------------------------------------------
# Step 2: Download the raw file (skipped if it already exists)
# -----------------------------------------------------------------------------

echo "[2/4] Downloading ${FILE_NAME}"
if [ -f "${RAW_GZ}" ]; then
    echo "  File already exists, skipping download"
else
    curl -L --fail -o "${RAW_GZ}" "${URL}"
fi

# -----------------------------------------------------------------------------
# Step 3: Decompress (keeps the original .gz; skipped if the CSV exists)
# -----------------------------------------------------------------------------

echo "[3/4] Decompressing"
if [ -f "${RAW_CSV}" ]; then
    echo "  CSV already exists, skipping decompression"
else
    gunzip -k "${RAW_GZ}"
fi

# -----------------------------------------------------------------------------
# Step 4: Convert CSV to GeoParquet (skipped if the output exists)
# -----------------------------------------------------------------------------

echo "[4/4] Converting to GeoParquet"
if [ -f "${OUT_PARQUET}" ]; then
    echo "  Parquet already exists, skipping conversion"
else
    ogr2ogr -f Parquet "${OUT_PARQUET}" "${RAW_CSV}" \
        -oo X_POSSIBLE_NAMES=BEGIN_LON \
        -oo Y_POSSIBLE_NAMES=BEGIN_LAT \
        -a_srs EPSG:4326
fi

echo "Done. Output: ${OUT_PARQUET}"
echo "Open it in DuckDB:"
echo "  duckdb -c \"INSTALL spatial; LOAD spatial; SELECT COUNT(*) FROM read_parquet('${OUT_PARQUET}');\""
