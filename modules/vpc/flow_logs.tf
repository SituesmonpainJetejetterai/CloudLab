resource "aws_flow_log" "aws_flow_log" {
  iam_role_arn    = aws_iam_role.aws_vpc_cloudwatch_log_group_role.arn
  log_destination = aws_cloudwatch_log_group.aws_vpc_cloudwatch_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.aws_vpc.id
}

resource "aws_cloudwatch_log_group" "aws_vpc_cloudwatch_log_group" {
  name = "aws_vpc_cloudwatch_log_group"
}

resource "aws_cloudwatch_log_stream" "aws_vpc_cloudwatch_log_stream" {
  name           = "aws_vpc_cloudwatch_log_stream_1"
  log_group_name = aws_cloudwatch_log_group.aws_vpc_cloudwatch_log_group.name
}

data "aws_iam_policy_document" "aws_vpc_cloudwatch_log_group_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "aws_vpc_cloudwatch_log_group_role" {
  name               = "aws_vpc_cloudwatch_log_group_role"
  assume_role_policy = data.aws_iam_policy_document.aws_vpc_cloudwatch_log_group_policy.json
}

data "aws_iam_policy_document" "aws_vpc_cloudwatch_log_group_policy_Logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "aws_vpc_cloudwatch_log_group_policy_amendment" {
  name   = "aws_vpc_cloudwatch_log_group_policy_amendment"
  role   = aws_iam_role.aws_vpc_cloudwatch_log_group_role.id
  policy = data.aws_iam_policy_document.aws_vpc_cloudwatch_log_group_policy_Logging.json
}

# Outputs

output "log_group_id" {
  value = aws_cloudwatch_log_group.aws_vpc_cloudwatch_log_group.id
}

output "log_group_iam_role" {
  value = aws_iam_role.aws_vpc_cloudwatch_log_group_role.arn
}
