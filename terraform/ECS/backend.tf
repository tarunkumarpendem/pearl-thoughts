terraform {
  backend "s3" {
    bucket         = "terrafrom-ecs-statefile"
    dynamodb_table = "ecs-statefile-lock-table"
    key            = "ecs"
    region         = "us-east-1"
  }
}