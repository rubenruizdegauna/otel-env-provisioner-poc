```shell
export TF_VAR_otlp_endpoint="OTLP_ENDPOINT"
export TF_VAR_nr_license_key="NR_LICENSE_KEY"
export TF_VAR_pvt_key="PRIVATE_SSH_KEY"

# Dry-run
terraform plan

# Create infra
terraform apply

# Destroy infra
terraform destroy
```