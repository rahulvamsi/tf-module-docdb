data "aws_ssm_parameter" "credentials" {
  name = "mutable.docdb.${var.env}.credentials"
}

