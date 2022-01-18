#multiple similar hosts (i.e. apps)
module "ec2-instance" {
  source  = "registry.terraform.io/terraform-aws-modules/ec2-instance/aws"
  version = "3.4.0"

  for_each = toset( ["app1", "app2", "app3"] )

  name                   = "otel-env-multiple-${each.value}"
  subnet_id              = "subnet-09b64de757828cdd4"
  vpc_security_group_ids = ["sg-044ef7bc34691164a"]
  ami                    = "ami-04511222dedb7385d"
  instance_type          = "t3a.small"
  key_name               = "caos-dev-arm"

  tags = {
    Terraform   = "true"
    Environment = "dev"
    owning_team = "CAOS"
  }

}

#another hosts (i.e. collector gateway)
module "ec2-instance-gateway" {
  source  = "registry.terraform.io/terraform-aws-modules/ec2-instance/aws"
  version = "3.4.0"

  name          = "otel-env-multiple-gateway"
  ami           = "ami-04511222dedb7385d"
  instance_type = "t3a.small"
  key_name      = "caos-dev-arm"

  subnet_id              = "subnet-09b64de757828cdd4"
  vpc_security_group_ids = ["sg-044ef7bc34691164a"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
    owning_team = "CAOS"
  }

}

resource "null_resource" "cluster" {
  for_each = merge(module.ec2-instance.*[0], { gateway : module.ec2-instance-gateway })

  connection {
    host        = each.value.private_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.pvt_key)
  }

  provisioner "remote-exec" {
    inline = ["sudo apt update", "sudo apt install python3 -y", "echo Done!"]
  }
}

module "ansible-apps" {

  source  = "registry.terraform.io/cloudposse/ansible/null"
  version = "0.6.0"

  arguments = [
    "--user=ubuntu",
    format("-e otlp_endpoint=%s:4317", module.ec2-instance-gateway.private_ip),
    "--private-key ${var.pvt_key}",
    "-e nr_license_key=${var.nr_license_key}",
    "--ssh-common-args='-o StrictHostKeyChecking=no'",
    format("-i %s,", join(",", values(module.ec2-instance).*.private_ip)),
  ]

  playbook = "../../ansible/playbook.yaml"
  dry_run  = false
}

module "ansible-gateway" {

  source  = "registry.terraform.io/cloudposse/ansible/null"
  version = "0.6.0"

  arguments = [
    "--user=ubuntu",
    "-e otlp_endpoint=${var.otlp_endpoint}",
    "--private-key ${var.pvt_key}",
    "-e nr_license_key=${var.nr_license_key}",
    "-e collector_as_gw=true",
    "--ssh-common-args='-o StrictHostKeyChecking=no'",
    format("-i %s,", module.ec2-instance-gateway.private_ip),
  ]

  playbook = "../../ansible/playbook.yaml"
  dry_run  = false
}