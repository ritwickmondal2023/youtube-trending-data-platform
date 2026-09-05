# Data Dictionary

This document defines the datasets produced and consumed by the YouTube Trending Data Platform. It describes the structure, purpose, important attributes, derived fields, and partitioning strategy of the Bronze, Silver, and Gold layers.

The data model follows the pipeline's progression from raw API data to cleaned analytical datasets.

---

## 1. Data Lake Layers

| Layer | Purpose | Primary Format |
|---|---|---|
| Bronze | Raw ingested data preserved close to its source structure | JSON, CSV |
| Silver | Cleaned, standardized, and enriched datasets | Parquet |
| Gold | Aggregated datasets optimized for analytical use | Parquet |

---

# 2. Bronze Layer

## 2.1 `raw_statistics`

The `raw_statistics` dataset contains raw YouTube trending-video statistics collected during ingestion.

### Schema

| Column | Data Type | Description |
|---|---|---|
| `video_id` | string | Unique identifier of the YouTube video. |
| `trending_date` | string | Original date value associated with the video's trending record. |
| `title` | string | Title of the video. |
| `channel_title` | string | Name of the YouTube channel publishing the video. |
| `category_id` | bigint | YouTube category identifier associated with the video. |
| `publish_time` | string | Original publication timestamp/value of the video. |
| `tags` | string | Tags associated with the video. |
| `views` | bigint | Number of views recorded for the video. |
| `likes` | bigint | Number of likes recorded for the video. |
| `dislikes` | bigint | Number of dislikes recorded for the video. |
| `comment_count` | bigint | Number of comments recorded for the video. |
| `thumbnail_link` | string | URL of the video's thumbnail. |
| `comments_disabled` | boolean | Indicates whether comments are disabled for the video. |
| `ratings_disabled` | boolean | Indicates whether ratings are disabled for the video. |
| `video_error_or_removed` | boolean | Indicates whether the video encountered an error or was removed. |
| `description` | string | Description associated with the video. |
| `region` | string | Region associated with the dataset record. |

### Storage

- **Layer:** Bronze
- **Dataset:** `raw_statistics`
- **Format:** JSON
- **Partitioning:** Region/date-based storage organization

---

## 2.2 `raw_statistics_reference_data`

The `raw_statistics_reference_data` dataset contains category reference information returned by the YouTube Data API.

### Top-Level Schema

| Column | Data Type | Description |
|---|---|---|
| `kind` | string | Resource type identifier returned by the API. |
| `etag` | string | Entity tag associated with the API response. |
| `items` | array<struct<...>> | Collection of category reference records returned by the API. |
| `region` | string | Region associated with the reference-data response. |

### Nested `items` Structure

The `items` array contains category reference records. Each record includes category identifiers and category-title information originating from the API response.

### Storage

- **Layer:** Bronze
- **Dataset:** `raw_statistics_reference_data`
- **Format:** JSON
- **Partitioning:** Region-based storage organization

---

# 3. Silver Layer

The Silver layer contains structured and cleaned datasets produced from Bronze-layer data.

---

## 3.1 `clean_statistics`

The `clean_statistics` dataset contains standardized and enriched trending-video statistics.

### Schema

| Column | Data Type | Description |
|---|---|---|
| `video_id` | string | Unique identifier of the YouTube video. |
| `trending_date` | string | Original trending-date value retained from the source data. |
| `trending_date_parsed` | date/timestamp | Parsed representation of the trending date used for analytical processing. |
| `title` | string | Title of the video. |
| `channel_title` | string | Name of the YouTube channel. |
| `category_id` | bigint | YouTube category identifier. |
| `publish_time` | string | Original publication timestamp/value. |
| `tags` | string | Video tags. |
| `views` | bigint | Number of views. |
| `likes` | bigint | Number of likes. |
| `dislikes` | bigint | Number of dislikes. |
| `comment_count` | bigint | Number of comments. |
| `thumbnail_link` | string | URL of the video's thumbnail. |
| `comments_disabled` | boolean | Indicates whether comments are disabled. |
| `ratings_disabled` | boolean | Indicates whether ratings are disabled. |
| `video_error_or_removed` | boolean | Indicates whether the video encountered an error or was removed. |
| `description` | string | Video description. |
| `region` | string | Region associated with the record and partition key. |
| `like_ratio` | numeric | Derived measure representing the relationship between likes and views. |
| `engagement_rate` | numeric | Derived engagement measure based on the available engagement metrics. |
| `_processed_at` | timestamp | Timestamp indicating when the record was processed by the transformation pipeline. |
| `_job_name` | string | Name of the processing job that produced the record. |

### Key Transformations

The dataset is produced through a series of standardization and cleansing operations, including:

- schema normalization
- null handling
- region normalization
- trending-date parsing
- numeric value handling
- derived engagement metrics
- record deduplication

### Storage

- **Layer:** Silver
- **Dataset:** `clean_statistics`
- **Format:** Parquet
- **Compression:** Parquet compression as configured by the processing job
- **Partition Key:** `region`

---

## 3.2 `clean_reference_data`

The `clean_reference_data` dataset contains the normalized category reference data used by downstream analytical transformations.

### Schema

| Column | Data Type | Description |
|---|---|---|
| `id` | string | YouTube category identifier. |
| `snippet.*` | source-derived fields | Flattened attributes originating from the category `snippet` structure in the API response. |
| `_ingestion_timestamp` | timestamp | Timestamp associated with ingestion of the reference data. |
| `_source_file` | string | Source Bronze object used to produce the record. |
| `region` | string | Region associated with the reference data and partition key. |

The `snippet.*` fields are derived from the nested `snippet` structure of the YouTube API response and retain the relevant source attributes present in the input.

### Storage

- **Layer:** Silver
- **Dataset:** `clean_reference_data`
- **Format:** Parquet
- **Partition Key:** `region`

---

# 4. Gold Layer

The Gold layer contains aggregated datasets designed for analytical querying and interpretation.

Three analytical datasets are produced:

1. `trending_analytics`
2. `channel_analytics`
3. `category_analytics`

All Gold datasets are stored as Parquet and partitioned by `region`.

---

## 4.1 `trending_analytics`

The `trending_analytics` dataset provides regional and date-level summaries of trending-video activity.

### Schema

| Column | Data Type | Description |
|---|---|---|
| `region` | string | Region associated with the aggregated records. |
| `trending_date_parsed` | date/timestamp | Parsed trending date used for aggregation. |
| `total_videos` | numeric | Total number of videos represented in the aggregation. |
| `total_views` | numeric | Total views across the aggregated videos. |
| `total_likes` | numeric | Total likes across the aggregated videos. |
| `total_dislikes` | numeric | Total dislikes across the aggregated videos. |
| `total_comments` | numeric | Total comments across the aggregated videos. |
| `avg_views_per_video` | numeric | Average views per video. |
| `avg_like_ratio` | numeric | Average like ratio across the aggregated records. |
| `avg_engagement_rate` | numeric | Average engagement rate across the aggregated records. |
| `max_views` | numeric | Highest view count represented in the aggregation. |
| `unique_channels` | numeric | Number of distinct channels represented in the aggregation. |
| `unique_categories` | numeric | Number of distinct categories represented in the aggregation. |
| `_aggregated_at` | timestamp | Timestamp indicating when the Gold aggregation was produced. |

### Storage

- **Layer:** Gold
- **Dataset:** `trending_analytics`
- **Format:** Parquet
- **Compression:** Snappy
- **Partition Key:** `region`

---

## 4.2 `channel_analytics`

The `channel_analytics` dataset summarizes trending performance at channel level.

### Schema

| Column | Data Type | Description |
|---|---|---|
| `channel_title` | string | Name of the YouTube channel. |
| `region` | string | Region associated with the aggregation. |
| `total_videos` | numeric | Number of videos represented for the channel. |
| `total_views` | numeric | Total views generated by the channel's represented videos. |
| `total_likes` | numeric | Total likes across the represented videos. |
| `total_comments` | numeric | Total comments across the represented videos. |
| `avg_views_per_video` | numeric | Average views per represented video. |
| `avg_engagement_rate` | numeric | Average engagement rate for the channel's represented videos. |
| `peak_views` | numeric | Highest individual video view count represented for the channel. |
| `times_trending` | numeric | Number of times the channel's videos appeared in the trending dataset. |
| `first_trending` | date/timestamp | Earliest trending date represented for the channel. |
| `last_trending` | date/timestamp | Latest trending date represented for the channel. |
| `categories` | string | Categories associated with the channel's represented videos. |
| `rank_in_region` | numeric | Channel ranking within the corresponding region based on the aggregation logic. |
| `_aggregated_at` | timestamp | Timestamp indicating when the Gold aggregation was produced. |

### Storage

- **Layer:** Gold
- **Dataset:** `channel_analytics`
- **Format:** Parquet
- **Compression:** Snappy
- **Partition Key:** `region`

---

## 4.3 `category_analytics`

The `category_analytics` dataset provides analytical summaries of trending performance by content category.

### Schema

| Column | Data Type | Description |
|---|---|---|
| `category_name` | string | Human-readable name of the content category. |
| `category_id` | numeric | YouTube category identifier. |
| `region` | string | Region associated with the aggregation. |
| `trending_date_parsed` | date/timestamp | Parsed trending date used in the aggregation. |
| `video_count` | numeric | Number of videos represented in the category aggregation. |
| `total_views` | numeric | Total views across the category's represented videos. |
| `total_likes` | numeric | Total likes across the represented videos. |
| `total_comments` | numeric | Total comments across the represented videos. |
| `avg_engagement_rate` | numeric | Average engagement rate for the category. |
| `unique_channels` | numeric | Number of distinct channels represented in the category. |
| `view_share_pct` | numeric | Percentage share of views represented by the category. |
| `_aggregated_at` | timestamp | Timestamp indicating when the Gold aggregation was produced. |

### Storage

- **Layer:** Gold
- **Dataset:** `category_analytics`
- **Format:** Parquet
- **Compression:** Snappy
- **Partition Key:** `region`

---

# 5. Dataset Lineage

The datasets follow the following logical progression:

```text
YouTube Data API
       │
       ▼
┌─────────────────────────────────┐
│ Bronze                           │
│                                 │
│ raw_statistics                  │
│ raw_statistics_reference_data   │
└─────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│ Silver                           │
│                                 │
│ clean_statistics                │
│ clean_reference_data            │
└─────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│ Gold                             │
│                                 │
│ trending_analytics              │
│ channel_analytics               │
│ category_analytics              │
└─────────────────────────────────┘
       │
       ▼
Amazon Athena