#######
# ECR #
#######

# resource "aws_ecr_repository" "ecs_ecr" {
#   name                 = var.ecs_details.ecr_name
#   image_tag_mutability = "IMMUTABLE"
#   image_scanning_configuration {
#     scan_on_push = true
#   }
# }


#######
# VPC #
#######

resource "aws_vpc" "ecs_vpc" {
  cidr_block = var.network_details.vpc_cidr
  tags = {
    "Name" = var.network_details.vpc_tag
  }
}


###########
# Subnets #
###########

resource "aws_subnet" "ecs_subnets" {
  count             = length(var.network_details.subnet_tags)
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = cidrsubnet(var.network_details.vpc_cidr, 8, count.index)
  availability_zone = var.network_details.azs[count.index]
  tags = {
    "Name" = var.network_details.subnet_tags[count.index]
  }
  map_public_ip_on_launch = true
  depends_on              = [aws_vpc.ecs_vpc]
}


####################
# Internet Gateway #
####################

resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.ecs_vpc.id
  tags = {
    "Name" = var.network_details.igw_tag
  }
  depends_on = [
    aws_vpc.ecs_vpc,
    aws_subnet.ecs_subnets
  ]
}


###############
# Route Table #
###############

resource "aws_route_table" "ecs_route_table" {
  vpc_id = aws_vpc.ecs_vpc.id
  depends_on = [
    aws_vpc.ecs_vpc,
    aws_subnet.ecs_subnets,
    aws_internet_gateway.ecs_igw
  ]
}


#########
# Route #
#########

resource "aws_route" "ecs_route" {
  route_table_id         = aws_route_table.ecs_route_table.id
  destination_cidr_block = var.network_details.destination_cidr_block
  gateway_id             = aws_internet_gateway.ecs_igw.id
  depends_on             = [aws_route_table.ecs_route_table]
}


##########################
# RouteTable Association #
##########################

resource "aws_route_table_association" "ecs_route_table_association" {
  count          = length(var.network_details.subnet_tags)
  route_table_id = aws_route_table.ecs_route_table.id
  subnet_id      = aws_subnet.ecs_subnets[count.index].id
  depends_on     = [aws_route.ecs_route]
}


##################
# Security Group #
##################

resource "aws_security_group" "ecs_sg" {
  vpc_id      = aws_vpc.ecs_vpc.id
  name        = var.network_details.security_group_tag
  description = "Security group which will open all the ports and can be attached to ECS Cluster"
  ingress {
    description = "opening all the ports for ECS cluster to access"
    from_port   = 0
    to_port     = 65535
    protocol    = "TCP"
    cidr_blocks = [var.network_details.destination_cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.network_details.destination_cidr_block]
  }
  depends_on = [aws_route_table_association.ecs_route_table_association]
}

###############
# ECS Cluster #
###############

resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.ecs_details.ecs_cluster_name
  tags = {
    "Name" = var.ecs_details.ecs_cluster_name
  }
}


############
# ECS Role #
############

data "aws_iam_role" "ecs_role" {
  name = var.ecs_details.ecs_role_name
}

data "aws_iam_role" "task_definition_role" {
  name = var.ecs_details.task_definition_role
}


#######################
# ECS Task Definition #
#######################

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "ecstaskdefinition"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  task_role_arn            = data.aws_iam_role.task_definition_role.arn
  execution_role_arn       = data.aws_iam_role.ecs_role.arn
  cpu                      = var.ecs_details.ecs_cpu
  memory                   = var.ecs_details.ecs_memory
  container_definitions = jsonencode([{
    name      = var.ecs_details.container_name
    image     = var.ecs_details.image
    cpu       = var.ecs_details.container_cpu
    memory    = var.ecs_details.container_memory
    essential = true
    portMappings = [{
      containerPort = var.ecs_details.port
      hostPort      = var.ecs_details.port
    }]
  }])
  depends_on = [
    aws_ecs_cluster.ecs_cluster,
    data.aws_iam_role.ecs_role,
    data.aws_iam_role.task_definition_role
  ]
}


#############################
# ALB Configuration for ECS #
#############################

########################
# Target Group for ALB #
########################

resource "aws_lb_target_group" "ecs_target_group" {
  name        = var.alb_configuration.target_group_name
  port        = var.ecs_details.port
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.ecs_vpc.id
  health_check {
    interval            = 30
    path                = "/"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}


#######
# ALB #
#######

resource "aws_lb" "ecs_alb" {
  name               = var.alb_configuration.alb_name
  load_balancer_type = "application"
  internal           = false
  subnets = [
    aws_subnet.ecs_subnets[0].id,
    aws_subnet.ecs_subnets[1].id,
    aws_subnet.ecs_subnets[2].id,
  ]
  security_groups = [aws_security_group.ecs_sg.id]
  depends_on      = [aws_lb_target_group.ecs_target_group]
}


#################
# Listener Rule #
#################

# resource "aws_lb_listener_rule" "ecs_listener_rule" {
#   listener_arn = aws_lb.ecs_alb.arn
#   priority     = 100

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.ecs_target_group.arn
#   }

#   condition {
#     path_pattern {
#       values = ["/*"]
#     }
#   }
#   depends_on = [ aws_lb.ecs_alb ]
# }


###############
# ECS Service #
###############

resource "aws_ecs_service" "ecs_service" {
  name            = var.ecs_details.ecs_service_name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = var.ecs_details.ecs_service_desired_size
  launch_type     = "FARGATE"
  network_configuration {
    subnets = [
      aws_subnet.ecs_subnets[0].id,
      aws_subnet.ecs_subnets[1].id,
      aws_subnet.ecs_subnets[2].id,
    ]
    security_groups = [aws_security_group.ecs_sg.id]
  }
  load_balancer {
    container_name   = var.ecs_details.container_name
    container_port   = var.ecs_details.port
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
  }
  depends_on = [aws_lb.ecs_alb]
}


##################################
# Target Group Attachment to ECS #
##################################

# resource "aws_lb_target_group_attachment" "ecs_target_attachment" {
#   target_group_arn = aws_lb_target_group.ecs_target_group.arn
#   target_id        = aws_ecs_service.ecs_service.id
#   port             = var.ecs_details.port
#   depends_on       = [ aws_lb_target_group.ecs_target_group ]
# }