# NOAA Storms Pipeline

A one-command pipeline that downloads a year of NOAA Storm Events data, converts it to GeoParquet, and lands it ready for analysis in DuckDB, GeoPandas, or QGIS.

## What it does

`pipeline.sh` takes a year (default: 2024), pulls the raw `details` file from NOAA's public archive, decompresses it, and converts it to a single GeoParquet file at `data/processed/storms_{YEAR}.parquet`.

Total runtime: about 90 seconds for a typical year on a home internet connection.

## The data

- **Source:** [NOAA Storm Events Database](https://www.ncei.noaa.gov/data/storm-events/)
- **License:** Public domain (US federal data)
- **What's in it:** every recorded storm event in the United States for the given year, including type, location, and damages

## How to run it

Requires GDAL (for `ogr2ogr`) and standard Unix utilities (`curl`, `gunzip`).

```bash
git clone https://github.com/{your-username}/noaa-storms-pipeline.git
cd noaa-storms-pipeline
chmod +x pipeline.sh
./pipeline.sh
```

To run for a specific year:

```bash
./pipeline.sh 2025
```

## What I Learned

Shell syntax was harder than expected: parameter expansion like `${FILE_NAME%.gz}` and the `set -euo pipefail` safeguards were new to me, and I checked every `ogr2ogr` flag against `--help` instead of trusting generated commands. The hardest practical part was NOAA's file naming, where a creation date in each file name has to match the server listing exactly. Next time I would look that date up automatically instead of hardcoding it, so the script works for any year without manual edits.

## Stack

- **bash**: pipeline orchestration
- **curl**: data download
- **GDAL / ogr2ogr**: CSV to GeoParquet conversion
- **GeoParquet**: output format
- **Ginzip**: decompress data

