resource "aws_kinesis_stream" "data_stream" {
  name             = "my-data-stream"
  shard_count      = 1
  retention_period = 24

  tags = {
    Environment = "aws-machine-learning"
  }
}

resource "aws_kinesis_analytics_application" "data_analytics" {
  name = "kinesis-analytics-application"

  inputs {
    name_prefix = "app_prefix"

    kinesis_stream {
      resource_arn = aws_kinesis_stream.data_stream.arn
      role_arn     = aws_iam_role.data_analytics_role.arn
    }

    parallelism {
      count = 1
    }

    schema {

        #1
      record_columns {
        mapping = "$.results[0:].name.first"
        name     = "first"
        sql_type = "VARCHAR(8)"
      }
        #2
      record_columns {
        mapping = "$.results[0:].name.last"
        name     = "last"
        sql_type = "VARCHAR(8)"
      }
        #3
      record_columns {
        mapping = "$.results[0:].dob.age"
        name     = "age"
        sql_type = "INTEGER"
      }
        #4
      record_columns {
        mapping = "$.results[0:].gender"
        name     = "gender"
        sql_type = "VARCHAR(8)"
      }
        #5
      record_columns {
        mapping = "$.results[0:].location.coordinates.latitude"
        name     = "latitude"
        sql_type = "DECIMAL(8,4)"
      }
        #6
      record_columns {
        mapping = "$.results[0:].location.coordinates.longitude"
        name     = "longitude"
        sql_type = "DECIMAL(8,4)"
      }

      record_encoding = "UTF-8"

      record_format {
        mapping_parameters {
          json {
            record_row_path = "$"
          }
        }
      }
    }
  }

  outputs {
	name = "DESTINATION_USER_DATA"
    schema {
      record_format_type = "JSON"
    }


    kinesis_firehose {
      resource_arn = aws_kinesis_firehose_delivery_stream.data_firehose.arn
      role_arn = aws_iam_role.data_analytics_role.arn      
		}
  	}
}

resource "aws_iam_role" "data_analytics_role" {
  name               = "iam-data-analytics-role"
  assume_role_policy = file("${path.module}/iam-policies/data-analytics-trust.json")
}

data "template_file" "data_analytics_custom_policy_actions" {
  template = file("${path.module}/iam-policies/data-analytics-role-policy.json")
}

resource "aws_iam_policy" "data_analytics_custom_policy_actions" {
  name       = "iam-data-analytics-custom-policy-actions"
  policy     = data.template_file.data_analytics_custom_policy_actions.rendered
  depends_on = [data.template_file.data_analytics_custom_policy_actions]
}

resource "aws_iam_role_policy_attachment" "data_analytics_attach_custom_policy" {
  role       = aws_iam_role.data_analytics_role.name
  policy_arn = aws_iam_policy.data_analytics_custom_policy_actions.arn
  depends_on = [aws_iam_role.data_analytics_role]
}

resource "aws_kinesis_firehose_delivery_stream" "data_firehose" {
    name        = "kinesis-firehose-extended-s3-stream"
    destination = "extended_s3"

    extended_s3_configuration {
    role_arn   		   = aws_iam_role.firehose_role.arn
    bucket_arn 		   = aws_s3_bucket.bucket_firehose.arn
	buffer_size        = 1
	buffer_interval    = 60

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.lambda_processor.arn}:$LATEST"
        }
      }
    }
  }
}

resource "aws_s3_bucket" "bucket_firehose" {
  bucket = "data-aws-kinesis-pfraczyk"
  acl    = "private"
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose-data-role"
  assume_role_policy = file("${path.module}/iam-policies/data-firehose-trust.json")
}

data "template_file" "firehose_custom_policy_actions" {
  template = file("${path.module}/iam-policies/data-firehose-role-policy.json")
}

resource "aws_iam_policy" "firehose_custom_policy_actions" {
  name       = "iam-firehose-custom-policy-actions"
  policy     = data.template_file.firehose_custom_policy_actions.rendered
  depends_on = [data.template_file.firehose_custom_policy_actions]
}

resource "aws_iam_role_policy_attachment" "firehose_attach_custom_policy" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_custom_policy_actions.arn
  depends_on = [aws_iam_role.firehose_role]
}

resource "aws_iam_role" "lambda_iam" {
  name = "lambda_iam"
  assume_role_policy = file("${path.module}/iam-policies/lambda-firehose-trust.json")
}

data "template_file" "lambda_custom_policy_actions" {
  template = file("${path.module}/iam-policies/lambda-firehose-role-policy.json")
}

resource "aws_iam_policy" "lambda_custom_policy_actions" {
  name       = "iam-lambda-custom-policy-actions"
  policy     = data.template_file.lambda_custom_policy_actions.rendered
  depends_on = [data.template_file.lambda_custom_policy_actions]
}

resource "aws_iam_role_policy_attachment" "lambda_attach_custom_policy" {
  role       = aws_iam_role.lambda_iam.name
  policy_arn = aws_iam_policy.lambda_custom_policy_actions.arn
  depends_on = [aws_iam_role.lambda_iam]
}

resource "aws_lambda_function" "lambda_processor" {
  filename      = "files/index.zip"
  function_name = "firehose_lambda_processor"
  role          = aws_iam_role.lambda_iam.arn
  handler       = "index.handler"
  runtime       = "nodejs12.x"
  timeout		= 60
}