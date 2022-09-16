resource "aws_docdb_cluster" "main" {
  cluster_identifier              = "${var.env}-docdb"
  engine                          = "docdb"
  engine_version                  = var.engine_version
  master_username                 = local.username
  master_password                 = local.password
  skip_final_snapshot             = true
  db_subnet_group_name            = aws_docdb_subnet_group.main.name
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.main.name
  vpc_security_group_ids          = [aws_security_group.main.id]
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = var.instance_count
  identifier         = "${var.env}-docdb-${count.index}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.instance_class
}

resource "aws_docdb_subnet_group" "main" {
  name       = "${var.env}-docdb"
  subnet_ids = var.db_subnets_ids

  tags = {
    Name = "${var.env}-docdb"
  }
}

resource "aws_docdb_cluster_parameter_group" "main" {
  family      = "docdb4.0"
  name        = "${var.env}-docdb"
  description = "${var.env}-docdb"
}

resource "aws_security_group" "main" {
  name        = "${var.env}-docdb"
  description = "${var.env}-docdb"
  vpc_id      = var.vpc_id

  ingress {
    description = "DOCUMENTDB"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block, var.WORKSTATION_IP]
  }
  tags = {
    Name = "${var.env}-docdb"
  }
}

resource "null_resource" "mongodb-schema-apply" {
  provisioner "local-exec" {
    command = <<EOF
curl -s -L -o /tmp/mongodb.zip "https://github.com/roboshop-devops-project/mongodb/archive/main.zip"
cd /tmp
unzip -o mongodb.zip
cd mongodb-main
curl -L -O https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem
mongo --ssl --host ${aws_docdb_cluster.main.endpoint}:27017 --sslCAFile rds-combined-ca-bundle.pem --username ${local.username} --password ${local.password} <catalogue.js 
mongo --ssl --host ${aws_docdb_cluster.main.endpoint}:27017 --sslCAFile rds-combined-ca-bundle.pem --username ${local.username} --password ${local.password} <users.js
EOF
  }
}

