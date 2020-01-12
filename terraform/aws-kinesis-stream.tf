resource "aws_kinesis_stream" "data_stream" {
  name             = "my-data-stream"
  shard_count      = 1
  retention_period = 24

  tags = {
    Environment = "aws-machine-learning"
  }
}