module "ec2-instance" {
  source  = "registry.terraform.io/terraform-aws-modules/ec2-instance/aws"
  version = "3.4.0"

  name                   = "otel-env-single"
  ami                    = "ami-04511222dedb7385d"
  instance_type          = "t3a.small"
  key_name               = "caos-dev-arm"
  subnet_id              = "subnet-09b64de757828cdd4"
  vpc_security_group_ids = ["sg-044ef7bc34691164a"]
  user_data              = local.user_data

  tags = {
    Terraform   = "true"
    Environment = "dev"
    owning_team = "CAOS"
  }

}

module "ansible" {

  source  = "registry.terraform.io/cloudposse/ansible/null"
  version = "0.6.0"

  arguments = [
    "--user=ubuntu",
    "-e otlp_endpoint=${var.otlp_endpoint}",
    "--private-key ${var.pvt_key}",
    "-e nr_license_key=${var.nr_license_key}",
    "--ssh-common-args='-o StrictHostKeyChecking=no'",
    "-i ${module.ec2-instance.private_ip},",
  ]

  playbook = "../../ansible/playbook.yaml"
  dry_run  = false
}

