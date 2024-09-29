output "aws_public_subnet_ids" {
  value = module.cdp_aws_prereqs.aws_public_subnet_ids
}
output "aws_private_subnet_ids" {
  value = module.cdp_aws_prereqs.aws_private_subnet_ids
}