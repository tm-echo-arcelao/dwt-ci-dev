locals {
  common_tags = {
    Terraform   = true
    Creator     = var.tag_creator
    Environment = upper(var.environment)
  }
}

# IAM
locals {
  vm_role_name             = "${var.vm_name}-role-${var.environment}"
  instance_profile_name    = "${var.vm_name}-profile-${var.environment}"
  vm_execution_policy_name = "dwh-vm-execution-policy-${var.environment}"
}

# S3
locals {
  flow_logs_bucket_name = "${var.flow_logs_bucket_name}-${var.environment}"
  bucket_name           = "${var.bucket_name}-${var.environment}"
}