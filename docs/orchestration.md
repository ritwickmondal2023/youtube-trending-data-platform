# Step Functions Orchestration

The supplied state machine is a Standard workflow with these major stages:

1. Invoke the YouTube ingestion Lambda.
2. Wait 10 seconds in the current definition.
3. Run a Parallel state containing reference transformation and Bronze-to-Silver Glue processing.
4. Run the Data Quality Lambda.
5. Evaluate `quality_passed`.
6. On PASS, run the Silver-to-Gold Glue job.
7. Publish SUCCESS or an appropriate failure notification through SNS.

Retries are configured for Lambda and Glue Task states. Catch blocks route failures to SNS notifications.


