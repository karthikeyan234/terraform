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
  cpu                      = 1024
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.fargate_iam_role.arn
  task_role_arn            = aws_iam_role.fargate_iam_role.arn
}

#####################  ECS Task definition END #############

resource "aws_ecs_service" "ecs_service" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.production-fargate-cluster.id
  task_definition = aws_ecs_task_definition.springbootapp-task-definition.arn
  desired_count   = var.desired_task_number
  launch_type     = "FARGATE"
  #iam_role        = aws_iam_role.fargate_iam_role.arn

  # ordered_placement_strategy {
  #   type  = "binpack"
  #   field = "cpu"
  # }

  network_configuration {
    subnets          = data.terraform_remote_state.infrastructure.outputs.private_subnets
    security_groups  = [aws_security_group.app_security_group.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs_app_target_group.arn
    container_name   = var.ecs_service_name
    container_port   = var.docker_container_port
  }

  #depends_on      = [aws_iam_role_policy.fargate_iam_role_policy, aws_alb_listener_rule.ecs_alb_listener_rule]
  depends_on      = [aws_iam_role_policy_attachment.fargate_iam_role_policy, aws_alb_listener.default-listener-http]
}
#####################  ECS Service END #############

resource "aws_alb_target_group" "ecs_default_target_group" {
  name     = "${var.ecs_cluster_name}-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.infrastructure.outputs.vpc_id

  tags = {
    Name = "${var.ecs_cluster_name}-TG"
  }
}

#logs
resource "aws_cloudwatch_log_group" "springbootapp_log_group" {
  name = "${var.ecs_service_name}-LogGroup"
}
