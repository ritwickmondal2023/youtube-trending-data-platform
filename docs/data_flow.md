# Data Flow

## 1. Ingestion

`lambdas/youtube_ingestion/lambda_function.py` calls the YouTube Data API for each configured region and writes two types of JSON objects to the Bronze layer:

- Trending-video responses under `youtube/raw_statistics/`
- Category reference responses under `youtube/raw_statistics_reference_data/`

Objects are organized using region/date/hour or region/date prefixes together with an ingestion identifier.

The ingestion process covers all configured regions supported by the pipeline.

## 2. Bronze Statistics → Silver Statistics

The Bronze statistics dataset is read through the AWS Glue Data Catalog.

The Glue ETL job:

- detects API-based and Kaggle-style data structures
- standardizes the schema
- removes records with null `video_id`
- normalizes region codes
- parses the trending date
- fills numeric nulls with zero
- derives `like_ratio` and `engagement_rate`
- adds `_processed_at` and `_job_name`
- deduplicates records by video, region, and parsed trending date
- writes the transformed data as Parquet to the Silver layer
- partitions the Silver dataset by `region`

The Silver statistics layer therefore provides a cleaned, structured representation of the ingested trending-video data across the configured regions.

## 3. Bronze Reference JSON → Silver Reference Data

The reference-data Lambda reads the JSON object directly from Amazon S3 using Boto3 and normalizes the `items` array with Pandas.

The transformation:

- removes duplicate category IDs
- adds ingestion and source metadata
- derives the corresponding region
- writes the resulting dataset as Parquet to the Silver layer

`awswrangler` is used for the dataset write and AWS Glue Data Catalog integration, with the output partitioned by `region`.

## 4. Data Quality

The Data Quality Lambda queries up to 10,000 rows from each Silver table through Amazon Athena.

The validation process checks:

- required-column presence
- null percentage
- minimum sample size
- views value range
- timestamp freshness

The resulting quality status is used by the Step Functions workflow to determine whether downstream Gold-layer processing should proceed.

## 5. Silver → Gold

The Silver datasets are processed by the Gold Glue ETL job.

Where applicable, the statistics data is joined with category reference data, after which the transformation produces three analytical datasets:

- `trending_analytics`
- `channel_analytics`
- `category_analytics`

The Gold datasets are stored as Snappy-compressed Parquet and partitioned by `region`.

These datasets provide the analytical foundation for examining trending behaviour across regions, channels, categories, and related measures.

## 6. Analytics

Amazon Athena is used to query the Gold datasets for analytical exploration.

Typical analysis areas include:

- regional trending behaviour
- channel performance
- category performance
- views and engagement
- trending frequency
- rankings
- category and regional comparisons

Athena query results are stored in the configured Amazon S3 query-results location.