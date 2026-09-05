# Data Quality

## 1. Overview

The Data Quality layer validates the Silver datasets before the pipeline proceeds to Gold-layer processing.

A dedicated AWS Lambda function queries the Silver datasets through Amazon Athena and applies a defined set of validation rules. The resulting checks are returned as a structured quality report and evaluated by AWS Step Functions.

The overall validation outcome is represented by the `quality_passed` field.

---

## 2. Data Quality Checks

| Check | Condition | Dataset |
|---|---|---|
| Row Count | `row_count >= DQ_MIN_ROW_COUNT` | `clean_statistics`, `clean_reference_data` |
| Null Percentage | `null_percentage <= DQ_MAX_NULL_PERCENT` for each critical column | `clean_statistics`, `clean_reference_data` |
| Schema | No required columns are missing | `clean_statistics`, `clean_reference_data` |
| Value Range | No negative views and no views greater than 50 billion | `clean_statistics` |
| Freshness | Latest available pipeline timestamp is within 48 hours of the freshness cutoff | `clean_statistics`, `clean_reference_data` |

### Configured Thresholds

| Parameter | Value |
|---|---:|
| `DQ_MIN_ROW_COUNT` | 10 |
| `DQ_MAX_NULL_PERCENT` | 5% |
| Maximum `views` value | 50,000,000,000 |
| Freshness Window | 48 hours |

---

## 3. Critical Columns

### `clean_statistics`

The following columns are included in completeness validation:

- `video_id`
- `title`
- `channel_title`
- `views`
- `region`

### `clean_reference_data`

The following columns are included in completeness validation:

- `id`
- `region`

---

## 4. Check Definitions

### 4.1 Row Count

The row-count check verifies that the dataset satisfies the configured minimum record threshold.

**Condition**

    row_count >= DQ_MIN_ROW_COUNT

A result equal to or greater than the threshold is marked as `PASS`.

### 4.2 Null Percentage

The null-percentage check evaluates the completeness of each critical column independently.

**Condition**

    null_percentage <= DQ_MAX_NULL_PERCENT

With the configured threshold of 5%, any critical column with a null percentage greater than 5% fails its validation.

### 4.3 Schema

The schema check verifies that all required columns are present in the dataset.

**Condition**

    missing_columns = []

The check passes when no required column is missing.

### 4.4 Value Range

The value-range check is applied to the `views` column in `clean_statistics`.

The validation identifies:

- Negative view counts
- View counts greater than 50 billion

**Condition**

    negative_count = 0
    AND
    extreme_count = 0

Both conditions must be satisfied for the check to pass.

### 4.5 Freshness

The freshness check validates the recency of the latest available pipeline timestamp.

The validation uses the relevant processing or ingestion timestamp available in the Silver dataset.

**Condition**

    latest_timestamp >= freshness_cutoff

The configured freshness window is 48 hours.

---

## 5. Overall Quality Result

The Data Quality Lambda returns a structured result containing:

- `quality_passed`
- `checks_passed`
- `checks_total`
- `details`

The `details` collection contains the result of each individual validation, including the dataset, measured value, threshold where applicable, pass/fail status, and a descriptive message.

### Example Overall Result

  {  
    "ExecutedVersion": "$LATEST",
    "Payload": {
      "quality_passed": true,
      "checks_passed": 14,
      "checks_total": 14,
      "details": [
        {
          "check": "row_count",
          "table": "clean_statistics",
          "value": 10000,
          "threshold": 10,
          "passed": true,
          "message": "Row count: 10000 (min: 10)"
        },
        {
          "check": "null_pct",
          "table": "clean_statistics",
          "column": "video_id",
          "value": 0,
          "threshold": 5,
          "passed": "True",
          "message": "video_id null%: 0.00% (max: 5.0%)"
        },
        {
          "check": "null_pct",
          "table": "clean_statistics",
          "column": "title",
          "value": 0,
          "threshold": 5,
          "passed": "True",
          "message": "title null%: 0.00% (max: 5.0%)"
        },
        {
          "check": "null_pct",
          "table": "clean_statistics",
          "column": "channel_title",
          "value": 0,
          "threshold": 5,
          "passed": "True",
          "message": "channel_title null%: 0.00% (max: 5.0%)"
        },
        {
          "check": "null_pct",
          "table": "clean_statistics",
          "column": "views",
          "value": 0,
          "threshold": 5,
          "passed": "True",
          "message": "views null%: 0.00% (max: 5.0%)"
        },
        {
          "check": "null_pct",
          "table": "clean_statistics",
          "column": "region",
          "value": 0,
          "threshold": 5,
          "passed": "True",
          "message": "region null%: 0.00% (max: 5.0%)"
        },
        {
          "check": "schema",
          "table": "clean_statistics",
          "missing_columns": [],
          "passed": true,
          "message": "All expected columns present"
        },
        {
          "check": "value_range",
          "table": "clean_statistics",
          "column": "views",
          "negative_count": 0,
          "extreme_count": 0,
          "passed": "True",
          "message": "Views: 0 negative, 0 extreme (>50000000000)"
        },
        {
          "check": "freshness",
          "table": "clean_statistics",
          "latest_record": "2026-08-31 16:51:02.041000+00:00",
          "cutoff": "2026-08-29 16:52:20.128963+00:00",
          "passed": true,
          "message": "Latest: 2026-08-31 16:51:02.041000+00:00, Cutoff: 2026-08-29 16:52:20.128963+00:00"
        },
        {
          "check": "row_count",
          "table": "clean_reference_data",
          "value": 125,
          "threshold": 10,
          "passed": true,
          "message": "Row count: 125 (min: 10)"
        },
        {
          "check": "null_pct",
          "table": "clean_reference_data",
          "column": "id",
          "value": 0,
          "threshold": 5,
          "passed": "True",
          "message": "id null%: 0.00% (max: 5.0%)"
        },
        {
          "check": "null_pct",
          "table": "clean_reference_data",
          "column": "region",
          "value": 0,
          "threshold": 5,
          "passed": "True",
          "message": "region null%: 0.00% (max: 5.0%)"
        },
        {
          "check": "schema",
          "table": "clean_reference_data",
          "missing_columns": [],
          "passed": true,
          "message": "All expected columns present"
        },
        {
          "check": "freshness",
          "table": "clean_reference_data",
          "latest_record": "2026-08-31 16:47:20.011319+00:00",
          "cutoff": "2026-08-29 16:52:22.550170+00:00",
          "passed": true,
          "message": "Latest: 2026-08-31 16:47:20.011319+00:00, Cutoff: 2026-08-29 16:52:22.550170+00:00"
        }
      ]
    }
  }
    

---

## 6. Step Functions Quality Gate

The Data Quality result is consumed by AWS Step Functions.

The workflow evaluates:

    $.dq_result.Payload.quality_passed

The routing is:

    Silver Datasets
           |
           v
    Data Quality Lambda
           |
           v
    Evaluate Data Quality
           |
       +---+---+
       |       |
      PASS    FAIL
       |       |
       v       v
    Gold ETL   SNS Notification

When `quality_passed = true`, the workflow proceeds to the Silver-to-Gold Glue transformation.

When `quality_passed = false`, the workflow routes the execution to the Data Quality failure notification path through Amazon SNS.

---

# 7. Sample Validation Output

The following is a captured example of a successful Data Quality execution.

## 7.1 Overall Result

    {
      "quality_passed": true,
      "checks_passed": 14,
      "checks_total": 14
    }

## 7.2 `clean_statistics`

### Row Count

    {
      "check": "row_count",
      "table": "clean_statistics",
      "value": 10000,
      "threshold": 10,
      "passed": true,
      "message": "Row count: 10000 (min: 10)"
    }

### Null Percentage

    video_id        : 0.00%   PASS
    title           : 0.00%   PASS
    channel_title   : 0.00%   PASS
    views           : 0.00%   PASS
    region          : 0.00%   PASS

Maximum permitted null percentage: `5%`.

### Schema

    {
      "check": "schema",
      "table": "clean_statistics",
      "missing_columns": [],
      "passed": true
    }

### Value Range

    {
      "check": "value_range",
      "table": "clean_statistics",
      "column": "views",
      "negative_count": 0,
      "extreme_count": 0,
      "passed": true
    }

### Freshness

    {
      "check": "freshness",
      "table": "clean_statistics",
      "latest_record": "2026-08-31 16:51:02.041000+00:00",
      "cutoff": "2026-08-29 16:52:20.128963+00:00",
      "passed": true
    }

---

## 7.3 `clean_reference_data`

### Row Count

    {
      "check": "row_count",
      "table": "clean_reference_data",
      "value": 125,
      "threshold": 10,
      "passed": true,
      "message": "Row count: 125 (min: 10)"
    }

### Null Percentage

    id       : 0.00%   PASS
    region   : 0.00%   PASS

Maximum permitted null percentage: `5%`.

### Schema

    {
      "check": "schema",
      "table": "clean_reference_data",
      "missing_columns": [],
      "passed": true
    }

### Freshness

    {
      "check": "freshness",
      "table": "clean_reference_data",
      "latest_record": "2026-08-31 16:47:20.011319+00:00",
      "cutoff": "2026-08-29 16:52:22.550170+00:00",
      "passed": true
    }

---

# 8. Sample Execution Summary

| Dataset | Validation Result |
|---|---|
| `clean_statistics` | All checks passed |
| `clean_reference_data` | All checks passed |
| **Overall** | **14 / 14 checks passed** |

### Final Status

    quality_passed = true

The successful quality result allowed the workflow to continue to Gold-layer processing.