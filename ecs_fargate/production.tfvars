# remote state
remote_state_key = "PROD/infrastructure.tfstate"
remote_state_bucket = "terraform-karthi-rstate"

ecs_cluster_name = "Production-ECS-Cluster"
internet_cidr_blocks = "0.0.0.0/0"


# service variables
ecs_service_name = "springbootapp"
docker_container_port = 8080
desired_task_number = "2"
spring_profile = "default"
memory = 1024
docker_image_url = "341808978070.dkr.ecr.ap-south-1.amazonaws.com/terraform:latest"
