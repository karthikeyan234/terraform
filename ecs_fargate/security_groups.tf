#Security Group for ALB to traffic for ECS cluster
resource "aws_security_group" "ecs_alb_security_group" {
  name        = "${var.ecs_cluster_name}-ALB-SG"
  description = "Security Group for ALB to traffic for ECS cluster"
  vpc_id      = data.terraform_remote_state.infrastructure.outputs.vpc_id

  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Security Group for our application on FARGATE
resource "aws_security_group" "app_security_group" {
  name        = "${var.ecs_service_name}-SG"
  description = "Security group for springbootapp to communicate in and out"
  vpc_id      = data.terraform_remote_state.infrastructure.outputs.vpc_id

  ingress {
    from_port = 80
    protocol  = "TCP"
    to_port   = 80
    cidr_blocks = [data.terraform_remote_state.infrastructure.outputs.vpc_cidr_block]
    security_groups = [aws_security_group.ecs_alb_security_group.id]
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
