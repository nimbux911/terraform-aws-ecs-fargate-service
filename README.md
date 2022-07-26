[![Maintained by Nimbux911](https://img.shields.io/badge/maintained%20by-nimbux911.com-%235849a6.svg)](https://www.nimbux911.com/)

# terraform-aws-ecs-fargate-service

This module was created to create a fargate service cluster 

## Requirements

Terraform's remote state definition is a must to avoid hardcoding. The ECS Cluster, Task definition and Load Balancer are needed.

---

# IMPORTANT: 
**This module only deploy a fargate cluster services and load balancer logic.**

## Example

```
module "ecs_service" {
  source                     = "git@github.com:calibers/terraform-aws-ecs-fargate-service.git?ref=v1.0"
  fargate_services           = {
      service_name            = "service-name"
      task_definition_arn     = data.terraform_remote_state.ecs-task.outputs.aws_ecs_task_definition_td_arn
      service_desired_count   = var.environment == "prd" ? 3 : 1 
      lb_config               = [
        {
          target_group_arn = data.terraform_remote_state.ecs-lb.outputs.target_group_arn
          container_name   = var.container_name
          container_port   = 4000
        } 
      ]
    }
  cluster_id         = data.terraform_remote_state.ecs-cluster.outputs.fargate_id
  cluster_name       = "${var.environment}-${var.service_name}-ecs"
  security_group_ids = data.terraform_remote_state.ecs-cluster.outputs.fargate_sg_ids
  subnet_ids         = data.terraform_remote_state.vpc.outputs.public_subnets
  enable_autoscaling = true
  
  tags = {
      Environment = var.environment
  }
}

```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| cluster\_id | Cluster id where you need to create services | string | - | yes |
| cluster\_name | Name of the Cluster where you need to create services | string | - | yes |
| fargate\_services | Define fargate service information | map | `{}` | no |
| security\_group\_ids |  List of security groups ids we need to add this cluster service | list  | `[]` | no |
| subnet\_ids | private subnet ids | list(string) | - | no |
| enable\_autoscaling | Enable or disable autoscaling config | bool | - | yes |
| target\_group\_arn | ARN of the load balancer's target group | string | - | yes |
| container\_name | Name of the task's container | string | - | yes |
| container\_port | port of the task's container | number | - | yes |
| task\_definition\_arn | Task definition arn | string | - | yes |
| tags | A amount of tags added as a map | map | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| service\_name | Name of the service we created |
