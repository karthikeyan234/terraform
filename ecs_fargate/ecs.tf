provider "aws" {
  region = var.region
}

terraform  {
  backend "s3" {}
}

#provide data to read remote infrastructure_class
data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = "${var.remote_state_bucket}"
    key    = "${var.remote_state_key}"
    region = "${var.region}"
  }
}

resource "aws_ecs_cluster" "production-fargate-cluster" {
  name = var.ecs_cluster_name
}

resource "aws_alb" "ecs_cluster_alb" {
  name            = "${var.ecs_cluster_name}-ALB"
  internal        = false
  security_groups = [aws_security_group.ecs_alb_security_group.id]
  subnets = split(
    ",",
    join(
      ",",
      data.terraform_remote_state.infrastructure.outputs.public_subnets,
    ),
  )

  tags = {
    Name = "${var.ecs_cluster_name}-ALB"
  }
}

resource "aws_alb_target_group" "ecs_default_target_group" {
  name     = "${var.ecs_cluster_name}-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.infrastructure.outputs.vpc_id

  tags = {
    Name = "${var.ecs_cluster_name}-TG"
  }
}

resource "aws_iam_role" "ecs_cluster_role" {
  name               = "${var.ecs_cluster_name}-IAM-Role"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["ecs.amazonaws.com", "ec2.amazonaws.com", "application-autoscaling.amazonaws.com"]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy" "ecs_cluster_policy" {
  name   = "${var.ecs_cluster_name}-IAM-Policy"
  role   = aws_iam_role.ecs_cluster_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*",
        "ec2:*",
        "elasticloadbalancing:*",
        "ecr:*",
        "dynamodb:*",
        "cloudwatch:*",
        "s3:*",
        "rds:*",
        "sqs:*",
        "sns:*",
        "logs:*",
        "ssm:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

#####################  ECS Task definition START #############

data "template_file" "ecs_task_definition_template" {
  template = file("task_definition.json")

  vars = {
    task_definition_name  = var.ecs_service_name
    ecs_service_name      = var.ecs_service_name
    docker_image_url      = var.docker_image_url
    memory                = var.memory
    docker_container_port = var.docker_container_port
    spring_profile        = var.spring_profile
    region                = var.region
  }
}

resource "aws_ecs_task_definition" "springbootapp-task-definition" {
  container_definitions    = data.template_file.ecs_task_definition_template.rendered
  family                   = var.ecs_service_name
  cpu                      = 512
  memory                   = var.memory
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.fargate_iam_role.arn
  task_role_arn            = aws_iam_role.fargate_iam_role.arn
}

#####################  ECS Task definition END #############

#Task Ececution Role for FARGATE Task
resource "aws_iam_role" "fargate_iam_role" {
  name               = "${var.ecs_service_name}-IAM-Role"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
  {
    "Effect": "Allow",
    "Principal": {
      "Service": ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
    },
    "Action": "sts:AssumeRole"
  }
  ]
}
EOF

}

resource "aws_iam_role_policy" "fargate_iam_role_policy" {
  name = "${var.ecs_service_name}-IAM-Role-Policy"
  role = aws_iam_role.fargate_iam_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:*",
        "ecr:*",
        "logs:*",
        "cloudwatch:*",
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

}

#Security Group for our application on FARGATE
resource "aws_security_group" "app_security_group" {
  name        = "${var.ecs_service_name}-SG"
  description = "Security group for springbootapp to communicate in and out"
  vpc_id      = data.terraform_remote_state.infrastructure.outputs.vpc_id

  ingress {
    from_port = 8080
    protocol  = "TCP"
    to_port   = 8080
    cidr_blocks = [data.terraform_remote_state.infrastructure.outputs.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.ecs_service_name}-SG"
  }
}

#Target Group to register fargate task that we are going to use with load balancer
resource "aws_alb_target_group" "ecs_app_target_group" {
  name        = "${var.ecs_service_name}-TG"
  port        = var.docker_container_port
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.infrastructure.outputs.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/actuator/health"
    unhealthy_threshold = "2"
  }
  tags = {
    Name = "${var.ecs_service_name}-TG"
  }
}

#####################  ECS Service START #############
# resource "aws_ecs_service" "ecs_service" {
#   name            = var.ecs_service_name
#   task_definition = aws_ecs_task_definition.springbootapp-task-definition.arn
#   desired_count   = var.desired_task_number
#   cluster         = var.ecs_cluster_name
#   launch_type     = "FARGATE"
#
#   network_configuration {
#     #subnets          = [data.terraform_remote_state.infrastructure.outputs.public_subnets]
#     subnets =["subnet-09d58c1f5e3331a2d", "subnet-0b4ce42d4768ca31d"]
#     security_groups  = [aws_security_group.app_security_group.id]
#     assign_public_ip = true
#   }
#
#   load_balancer {
#     container_name   = var.ecs_service_name
#     container_port   = var.docker_container_port
#     target_group_arn = aws_alb_target_group.ecs_app_target_group.arn
#   }
# }
#####################  ECS Service END #############

#Application load balancer listener rule = so that we can attach our target group to the
#load balancer and to the acctual listener rule
# resource "aws_alb_listener_rule" "ecs_alb_listener_rule" {
#   #listener_arn      = data.terraform_remote_state.platform.outputs.ecs_alb_listener_arn
#   listener_arn       = aws_alb.ecs_cluster_alb.arn
#   action {
#     type             = "forward"
#     target_group_arn = aws_alb_target_group.ecs_app_target_group.arn
#   }
#
#   condition {
#     field  = "host-header"
#     #values = ["${lower(var.ecs_service_name)}.${data.terraform_remote_state.platform.outputs.ecs_domain_name}"]
#   }
# }
