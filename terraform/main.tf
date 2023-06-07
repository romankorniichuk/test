# Create ECR Repository
resource "aws_ecr_repository" "my_ecr_repository" {
  name = "my-ecr-repository"
}
#Create OpenVPN resources
resource "aws_instance" "openvpn" {
  ami           = "ami-03fa477d477703122"
  instance_type = "t2.micro"

  tags = {
    Name = "openvpn-instance"
  }
}
  resource "aws_security_group" "openvpn_sg" {
  name        = "openvpn-sg"
  description = "OpenVPN Security Group"

  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/24"
  #enable_dns_support   = true
  #enable_dns_hostnames = true
  tags = {
        Name = "My VPC"
  }
}

# Create Subnet
resource "aws_subnet" "pub_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.0.0/28"
}

# Create Security Group
resource "aws_security_group" "my_security_group" {
  name        = "my-security-group"
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 0
        to_port         = 65535
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

# Create ECS Cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

# Create Launch Configuration
resource "aws_launch_configuration" "my_launch_configuration" {
  name                 = "my-launch-configuration"
  image_id             = "ami-03fa477d477703122"  # Replace with your desired AMI ID
  instance_type        = "t2.micro"
  iam_instance_profile = "my-instance-profile"
  security_groups      = [aws_security_group.my_security_group.id]
}

# Create Autoscaling Group
resource "aws_autoscaling_group" "my_autoscaling_group" {
  name                 = "my-autoscaling-group"
  launch_configuration = aws_launch_configuration.my_launch_configuration.name
  min_size             = 1
  max_size             = 3
  desired_capacity     = 2
  vpc_zone_identifier  = [aws_subnet.my_subnet.id]
}

# Create Task Definition
resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "my-task"
  container_definitions    = jsonencode([
    {
      "name": "my-container",
      "image": aws_ecr_repository.my_ecr_repository.repository_url,
      "cpu": 32,
      "memory": 64,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp"
        }
      ]
    }
  ])
}

# Create Service
resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  desired_count   = 2

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = "my-target-group-arn"
    container_name   = "my-container"
    container_port   = 80
  }
} 