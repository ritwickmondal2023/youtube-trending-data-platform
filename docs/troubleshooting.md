# Troubleshooting

## S3 `ListBucket` AccessDenied

### Symptom
A Parquet write through AWS SDK for Pandas failed because the role could not perform `s3:ListBucket`.

### Root cause
`ListBucket` was attached to an object-style ARN (`bucket/*`) rather than the bucket ARN itself.

### Correction
Use the bucket ARN for `s3:ListBucket` and the object ARN for object operations.

### Lesson
IAM resource scopes are action-specific. A valid action plus an invalid resource ARN still results in `AccessDenied`.

## Athena query-result S3 AccessDenied

### Symptom
The Data Quality Lambda could execute Athena but the query failed while writing results to the S3 query-results location.

### Root cause
The role did not have the required permissions for the configured Athena results bucket.

### Correction
Grant the required S3 permissions to the Athena results location and the necessary Athena API actions. AWS documents the relationship between Athena query results and S3 access: https://docs.aws.amazon.com/athena/latest/ug/querying.html

### Lesson
The S3 bucket containing the Athena results is a separate resource from the S3 location containing the analytical data.

## Step Functions `SNS:Publish` AccessDenied

### Symptom
The state machine failed at an SNS Publish state.

### Root cause
The execution role had a resource/region mismatch for the topic ARN.

### Correction
Use the exact deployed SNS topic ARN in the Step Functions role policy and keep the region consistent.

### Lesson
Step Functions uses its own execution role. Permissions on the Lambda role do not automatically grant permissions to the Step Functions role.

## Reference transformation input mismatch

### Symptom
The JSON-to-Parquet Lambda can receive a direct Step Functions invocation with no S3 event records.

### Root cause
The Lambda implementation expects `Records[*].s3` information to identify the object to read.

### Status
This is a correctness item to fix before claiming fully automated end-to-end orchestration.
