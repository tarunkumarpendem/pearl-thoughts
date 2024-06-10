variable "region" {
  type    = string
  default = "us-east-1"
}

variable "network_details" {
  type = object({
    vpc_cidr               = string
    vpc_tag                = string
    azs                    = list(string)
    subnet_tags            = list(string)
    igw_tag                = string
    route_table_tag        = string
    destination_cidr_block = string
    security_group_tag     = string
  })
  default = {
    vpc_cidr               = "10.10.0.0/16"
    vpc_tag                = "ecs-vpc"
    azs                    = ["us-east-1a", "us-east-1b", "us-east-1c"]
    subnet_tags            = ["ecs-subnet-1", "ecs-subnet-2", "ecs-subnet-3"]
    igw_tag                = "ecs-igw"
    route_table_tag        = "ecs-rt"
    destination_cidr_block = "0.0.0.0/0"
    security_group_tag     = "ecs-sg"
  }
}

variable "ecs_details" {
  type = object({
    ecs_role_name            = string
    ecs_cluster_name         = string
    cloudwatch_loggroup_name = string
    ecs_service_name         = string
    container_name           = string
    image                    = string
    ecs_cpu                  = number
    ecs_memory               = number
    container_cpu            = number
    container_memory         = number
    ecs_service_desired_size = number
    port                     = number
    task_definition_role     = string
    # ecr_name                 = string
  })
  default = {
    ecs_role_name            = "ecsTaskExecutionRole"
    ecs_cluster_name         = "ecs-cluster-terraform"
    cloudwatch_loggroup_name = "ecs-loggroup-terraform"
    ecs_service_name         = "ecs-service-terraform"
    container_name           = "ecs-container"
    image                    = "232589951422.dkr.ecr.us-east-1.amazonaws.com/ecs-ecr:pearlthoughts-1"
    container_cpu            = 256
    container_memory         = 512
    ecs_cpu                  = 512
    ecs_memory               = 1024
    ecs_service_desired_size = 1
    port                     = 3000
    task_definition_role     = "taskRoleArn"
    # ecr_name                 = "ecs-ecr-terraform"
  }
}

variable "alb_configuration" {
  type = object({
    target_group_name = string
    alb_name          = string
  })
  default = {
    target_group_name = "ecs-tg-terraform"
    alb_name          = "ecs-alb-terraform"
  }
}