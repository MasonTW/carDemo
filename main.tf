provider "aws" {
  region  = "us-east-1"
  profile = "tw-aws-beach"
}

//dynamodb
resource "aws_dynamodb_table" "park-dynamodb-table" {
  name           = "CarParking"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "car_no"
  range_key      = "car_in_time"

  attribute {
    name = "car_no"
    type = "S"
  }

  attribute {
    name = "car_in_time"
    type = "N"
  }

  attribute {
    name = "car_state"
    type = "S"
  }

  global_secondary_index {
    hash_key           = "car_state"
    range_key          = "car_in_time"
    name               = "car_state-car_in_time-index"
    projection_type    = "INCLUDE"
    write_capacity     = 10
    read_capacity      = 10
    non_key_attributes = ["car_no"]
  }
}
resource "aws_dynamodb_table" "record-dynamodb-table" {
  name           = "CarRecord"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "car_state"
  range_key      = "car_no"

  attribute {
    name = "car_state"
    type = "S"
  }

  attribute {
    name = "car_no"
    type = "B"
  }

}

resource "aws_iam_role" "iam_all" {
  name                = "iam"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess", "arn:aws:iam::aws:policy/AmazonSNSFullAccess"]
  assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}



//Rules
resource "aws_iot_topic_rule" "rule_car_record" {
  name        = "car_record"
  description = "car_record"
  enabled     = true
  sql         = "SELECT * FROM 'topic/car' where state ='car_in' and state = 'car_out'"
  sql_version = "2016-03-23"
  lambda {
    function_arn = aws_lambda_function.car_record_function.arn
  }
}

resource "aws_iot_topic_rule" "rule_car_in" {
  name        = "car_in"
  description = "car_in"
  enabled     = true
  sql         = "SELECT * FROM 'topic/car' where state ='car_in'"
  sql_version = "2016-03-23"
  lambda {
    function_arn = aws_lambda_function.car_in_function.arn
  }
}

resource "aws_lambda_permission" "allow_car_in_rule" {
  statement_id  = "AllowExecutionFromRule"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.car_in_function.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = "arn:aws:iot:us-east-1:160071257600:rule/car_in"
}

resource "aws_lambda_permission" "allow_car_out_rule" {
  statement_id  = "AllowExecutionFromRule"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.car_out_function.function_name
  principal     = "iot.amazonaws.com"
  source_arn    = "arn:aws:iot:us-east-1:160071257600:rule/car_out"
}

resource "aws_iot_topic_rule" "rule_car_out" {
  name        = "car_out"
  description = "car_record"
  enabled     = true
  sql         = "SELECT * FROM 'topic/car' where state = 'car_out'"
  sql_version = "2016-03-23"
  lambda {
    function_arn = aws_lambda_function.car_out_function.arn
  }
}


resource "aws_lambda_function" "car_in_function" {
  filename         = "car_in.zip"
  function_name    = "CarIn"
  handler          = "car_in.handler"
  role             = aws_iam_role.iam_all.arn
  source_code_hash = data.archive_file.car_in_function_source.output_base64sha256
  runtime          = "nodejs14.x"
  timeout          = 100
}

data "archive_file" "car_in_function_source" {
  type        = "zip"
  source_file = "./car_in.js"
  output_path = "car_in.zip"
}

resource "aws_lambda_function" "car_out_function" {
  filename         = "car_out.zip"
  function_name    = "CarOut"
  handler          = "car_out.handler"
  role             = aws_iam_role.iam_all.arn
  source_code_hash = data.archive_file.car_in_function_source.output_base64sha256
  runtime          = "nodejs14.x"
  timeout          = 100
}

data "archive_file" "car_out_function_source" {
  type        = "zip"
  source_file = "./car_out.js"
  output_path = "car_out.zip"
}

resource "aws_lambda_function" "car_record_function" {
  filename         = "car_record.zip"
  function_name    = "carRecord"
  handler          = "car_record.handler"
  role             = aws_iam_role.iam_all.arn
  source_code_hash = data.archive_file.car_in_function_source.output_base64sha256
  runtime          = "nodejs14.x"
  timeout          = 100
}

data "archive_file" "car_record_function_source" {
  type        = "zip"
  source_file = "./car_record.js"
  output_path = "car_record.zip"
}
resource "aws_sns_topic" "car_info" {
  name            = "car_info"
  delivery_policy = <<EOF
{
  "http": {
    "defaultHealthyRetryPolicy": {
      "minDelayTarget": 20,
      "maxDelayTarget": 20,
      "numRetries": 3,
      "numMaxDelayRetries": 0,
      "numNoDelayRetries": 0,
      "numMinDelayRetries": 0,
      "backoffFunction": "linear"
    },
    "disableSubscriptionOverrides": false,
    "defaultThrottlePolicy": {
      "maxReceivesPerSecond": 1
    }
  }
}
EOF
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = "arn:aws:sns:us-east-1:160071257600:car_info"
  protocol  = "email"
  endpoint  = "mingxin.wang@thoughtworks.com"
}