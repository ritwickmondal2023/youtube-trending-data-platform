# IAM and Security

## Public repository rule
Placeholders are used such as `<AWS_ACCOUNT_ID>`, `<AWS_REGION>`, `<BRONZE_BUCKET>`, and `<SNS_TOPIC_ARN>` in examples.

## Permission model

### YouTube ingestion Lambda

Requires access to write raw API output to the Bronze bucket. If this Lambda publishes partial-failure notifications, it also requires `sns:Publish` to the notification topic.

### JSON-to-Parquet Lambda

Requires:

- `s3:GetObject` on Bronze objects
- `s3:PutObject` on Silver objects
- bucket-level `s3:ListBucket` when the underlying write operation needs to enumerate objects/partitions
- Glue catalog permissions when `awswrangler` updates the table
- `sns:Publish` if the function sends alerts

### Data Quality Lambda

Requires Athena query execution/read permissions plus S3 access to the configured Athena results location. Athena's documentation states that `GetQueryResults` requires S3 `GetObject` access to the query-results location. See: https://docs.aws.amazon.com/athena/latest/APIReference/API_GetQueryResults.html

### Step Functions execution role

The state machine's role needs the permissions required by the service integrations it invokes, including Lambda invocation, Glue job execution, and SNS publish to the configured topic. AWS documents `sns:Publish` permissions for the SNS integration here: https://docs.aws.amazon.com/step-functions/latest/dg/connect-sns.html

## S3 ARN distinction

Bucket-level action example:

```text
arn:aws:s3:::<BUCKET_NAME>
```

Object-level action example:

```text
arn:aws:s3:::<BUCKET_NAME>/*
```

`ListBucket` is a bucket-level permission; `GetObject` and `PutObject` are object-level permissions.

