module "codedeploy" {
  source = "../modules/codedeploy"

  app_name = var.app_name
  deployment_group_name = var.deployment_group_name
  ec2_tag_filter = var.ec2_tag_filter
  vm_role_name = local.vm_role_name
}