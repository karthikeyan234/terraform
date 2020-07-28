# #Task Ececution Role for FARGATE Task
# resource "aws_iam_role" "fargate_iam_role" {
#   name               = "${var.ecs_service_name}-IAM-Role"
#   assume_role_policy = <<EOF
# {
# "Version": "2012-10-17",
# "Statement": [
#   {
#     "Effect": "Allow",
#     "Principal": {
#       "Service": ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
#     },
#     "Action": "sts:AssumeRole"
#   }
#   ]
# }
# EOF
# }
#
# resource "aws_iam_role_policy" "fargate_iam_role_policy" {
#   name = "${var.ecs_service_name}-IAM-Role-Policy"
#   role = aws_iam_role.fargate_iam_role.id
#
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ecs:*",
#         "ecr:*",
#         "logs:*",
#         "cloudwatch:*",
#         "elasticloadbalancing:*"
#       ],
#       "Resource": "*"
#     }
#   ]
# }
# EOF
# }

# ECS task execution role data
data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid = ""
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS task execution role
resource "aws_iam_role" "fargate_iam_role" {
  name               = "${var.ecs_service_name}-IAM-Role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
}

# ECS task execution role policy attachment
resource "aws_iam_role_policy_attachment" "fargate_iam_role_policy" {
  role       = aws_iam_role.fargate_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}























# resource "aws_iam_role" "ecs_cluster_role" {
#   name               = "${var.ecs_cluster_name}-IAM-Role"
#   assume_role_policy = <<EOF
# {
# "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": ["ecs.amazonaws.com", "ec2.amazonaws.com", "application-autoscaling.amazonaws.com"]
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# EOF
#
# }
#
# resource "aws_iam_role_policy" "ecs_cluster_policy" {
#   name   = "${var.ecs_cluster_name}-IAM-Policy"
#   role   = aws_iam_role.ecs_cluster_role.id
#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ecs:*",
#         "ec2:*",
#         "elasticloadbalancing:*",
#         "ecr:*",
#         "dynamodb:*",
#         "cloudwatch:*",
#         "s3:*",
#         "rds:*",
#         "sqs:*",
#         "sns:*",
#         "logs:*",
#         "ssm:*"
#       ],
#       "Resource": "*"
#     }
#   ]
# }
# EOF
#
# }
