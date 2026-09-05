# Engineering Design Decisions

This document records the key architectural and technology decisions made for the YouTube Trending Data Platform on AWS. The decisions are based on the requirements of the Version 1 pipeline, the characteristics of the workload, and the capabilities of the selected AWS services.

The objective is to maintain a clear separation between raw ingestion, data transformation, validation, and analytical consumption while keeping the architecture manageable and largely serverless.

---

## 1. Amazon S3 as the Data Lake Storage Layer

Amazon S3 was selected as the primary storage layer because the pipeline follows a data-lake architecture and requires separate storage stages for raw, processed, and analytical datasets.

S3 provides durable object storage and integrates directly with other services used in the pipeline, including AWS Glue and Amazon Athena. This makes it suitable for storing the Bronze, Silver, and Gold datasets without introducing a separate storage platform.

The Version 1 implementation uses S3 as the persistent storage foundation for the pipeline.

---

## 2. Bronze, Silver, and Gold Data Layers

The pipeline uses a Bronze/Silver/Gold layered architecture to separate different stages of data processing and improve data lineage.

### Bronze

The Bronze layer contains raw data received from the YouTube API. The data is preserved in its original JSON-oriented form and acts as the initial landing area for ingestion.

### Silver

The Silver layer contains transformed and cleaned datasets. Data is converted into Parquet format and undergoes processing such as schema handling, type conversion, null handling, cleansing, and other transformations implemented by the pipeline.

### Gold

The Gold layer contains aggregated datasets designed for downstream analytical use. The Silver-to-Gold transformation applies business-oriented aggregations and produces regional analytical datasets.

This separation makes the pipeline easier to understand, maintain, troubleshoot, and extend while providing a clear lineage from source data to analytical output.

---

## 3. AWS Lambda for Lightweight Processing

AWS Lambda was selected for workloads that are relatively lightweight and event- or invocation-driven.

The YouTube ingestion function uses Lambda to call the YouTube Data API and store the retrieved data in Amazon S3. Lambda is also used for the JSON-to-Parquet reference-data transformation and for executing the Data Quality validation logic.

These workloads do not require a continuously running compute environment, making a serverless execution model appropriate for Version 1.

Lambda is therefore used selectively rather than as the primary processing engine for all transformations.

---

## 4. AWS Glue and PySpark for Data Transformation

AWS Glue with PySpark is used for the more data-processing-oriented ETL workloads.

The Bronze-to-Silver statistics transformation performs dataframe-based cleansing and transformation operations, while the Silver-to-Gold job performs aggregation and preparation of analytical datasets.

Glue provides a managed Spark execution environment together with integration with the AWS Glue Data Catalog. This allows the pipeline to perform distributed data processing without managing Spark infrastructure directly.

The use of Glue is therefore complementary to Lambda: Lambda handles lightweight processing, while Glue handles the more substantial dataframe-oriented ETL workloads.

---

## 5. Parquet as the Processed Data Format

Parquet was selected as the primary storage format for Silver and Gold datasets.

The pipeline is designed primarily for analytical workloads rather than transactional row-level operations. A columnar format such as Parquet is therefore appropriate for storing processed analytical datasets and supporting selective reads through Amazon Athena.

Using Parquet also provides a consistent structured format across the processed layers of the data lake.

---

## 6. Region-Based Partitioning

The current implementation uses `region` as the partition key for the processed datasets.

Regional separation is relevant to the analytical objective of the project and provides a natural organizational boundary for the data. Partitioning by region also allows queries that filter by region to work against the corresponding partitioned dataset rather than treating the entire dataset as a single logical storage area.

`trending_date` remains an analytical column in Version 1 rather than being used as a partition key.

This decision reflects the current workload and implementation and does not imply that region is the optimal partitioning strategy for every future version of the platform.

---

## 7. Amazon Athena as the Analytical Query Layer

Amazon Athena was selected as the SQL query layer because the analytical datasets are stored in Amazon S3 and do not require a continuously running database cluster.

Athena provides serverless SQL-based querying directly against S3-backed datasets and integrates with the AWS Glue Data Catalog for table and schema metadata.

Within the project, Athena serves two purposes:

- Data Quality validation against processed datasets
- Analytical querying of Gold-layer datasets

This allows the project to perform both validation and exploration without introducing a separate analytical database platform.

---

## 8. AWS Step Functions for Workflow Orchestration

AWS Step Functions was selected as the orchestration layer for the end-to-end pipeline.

The state machine makes the workflow sequence explicit and provides control over:

- task execution order
- parallel processing
- retries
- failure handling
- conditional Data Quality routing
- downstream Gold processing
- success and failure notifications

A notable design decision in Version 1 is the use of a `Parallel` state for the reference-data transformation and the Bronze-to-Silver statistics transformation. These branches can execute independently before the workflow proceeds to Data Quality validation.

Step Functions therefore acts as the control plane for the pipeline rather than performing the data transformations itself.

---

## 9. Amazon SNS for Pipeline Notifications

Amazon SNS is used as the notification mechanism for pipeline execution outcomes.

The workflow publishes notifications for successful completion as well as failure or warning conditions, including ingestion failures, transformation failures, Data Quality failures, and Gold-layer failures.

SNS provides a simple publish/subscribe model that allows the pipeline to communicate operational events without coupling the processing components directly to an email-delivery implementation.

---

## 10. AWS IAM for Access Control

AWS IAM is used to control access between the services participating in the pipeline.

Execution roles and policies provide the permissions required by Lambda, Step Functions, Glue, Athena, S3, and SNS to perform their respective operations.

The implementation also demonstrates an important IAM distinction between bucket-level and object-level S3 permissions. For example, operations such as `s3:ListBucket` operate against the bucket ARN, while object operations such as `s3:GetObject` and `s3:PutObject` operate against object ARNs.

The intention is to grant application components only the permissions required for their respective responsibilities rather than relying on broad administrative access for runtime services.

---

## 11. AWS Wrangler for DataFrame-to-Parquet Integration

The JSON-to-Parquet Lambda uses `awswrangler` to simplify the process of writing pandas DataFrames as Parquet datasets to Amazon S3 and integrating those datasets with the AWS Glue Data Catalog.

The function still uses Boto3 directly where lower-level AWS service interaction is appropriate, such as retrieving the source JSON object from Amazon S3.

This provides a practical separation of responsibilities:

- **Boto3** for direct AWS service operations
- **awswrangler** for data-engineering-oriented dataframe, Parquet, S3 dataset, and Glue Catalog operations

The choice reduces boilerplate while keeping the implementation within the Python-based AWS ecosystem.

---

## 12. Design Principle: Use the Simplest Suitable Service

Version 1 intentionally does not use a single AWS service for every workload.

Instead, the architecture assigns responsibilities according to workload characteristics:

| Requirement | Selected Service |
|---|---|
| API ingestion | AWS Lambda |
| Raw storage | Amazon S3 |
| Lightweight reference transformation | AWS Lambda |
| Dataframe-oriented ETL | AWS Glue / PySpark |
| Metadata management | AWS Glue Data Catalog |
| Data Quality validation | AWS Lambda + Amazon Athena |
| Workflow orchestration | AWS Step Functions |
| Notifications | Amazon SNS |
| Analytical querying | Amazon Athena |
| Logging and execution diagnostics | Amazon CloudWatch |
| Access control | AWS IAM |

This separation keeps the responsibilities of each component clear and avoids introducing additional infrastructure without a demonstrated requirement.


