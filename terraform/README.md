This terraform template will create infrastructure for AWS Kinesis using Streams, Data Analytics and Firehose with Lambda.
Data will be automatic pulled with python script using GET request from https://randomuser.me/api/?exc=login 
and pushed into the stream. After creating it is needed to start the application in Data Analytics and
use SQL Query from the /files.
It will transform and send the data into S3 Bucket. Before deleting you have to empty the bucket.

TODO - create variables.tf
