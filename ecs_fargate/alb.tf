//Internet facing load balancer
resource "aws_alb" "ecs_cluster_alb" {
  name            = "${var.ecs_cluster_name}-ALB"
  internal        = false //internet facing LB
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

resource "aws_alb_listener" "default-listener-http" {
  load_balancer_arn = aws_alb.ecs_cluster_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.ecs_app_target_group.arn

    }
}

#Application load balancer listener rule = so that we can attach our target group to the
#load balancer and to the acctual listener rule
resource "aws_alb_listener_rule" "ecs_alb_listener_rule" {
  #listener_arn      = data.terraform_remote_state.platform.outputs.ecs_alb_listener_arn
  listener_arn       = aws_alb_listener.default-listener-http.arn
  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_app_target_group.arn
  }

  condition {
    #field  = "host-header"
    #values = ["${lower(var.ecs_service_name)}.${data.terraform_remote_state.platform.outputs.ecs_domain_name}"]
    host_header {
      values = [aws_alb.ecs_cluster_alb.dns_name]
    }
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
    path                = "/"
    unhealthy_threshold = "2"
  }
  tags = {
    Name = "${var.ecs_service_name}-TG"
  }
}
