provider "aws" {
  region = "us-east-1"
}
data "aws_vpc" "default" {
  default = true
}
resource "aws_security_group" "ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id #var.vpc_id # or use data source for default VPC

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # for testing, restrict later
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "private_key" {}
variable "public_key" {
  description = "The contents of the public SSH key"
  type        = string
}

resource "aws_key_pair" "deployer" {
  key_name   = "rails-key"
  public_key = var.public_key
}

resource "aws_instance" "app" {
  ami           = "ami-007855ac798b5175e" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "RailsAppServer"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y gnupg2 curl git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev",
      "gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3",
      "curl -sSL https://get.rvm.io | bash -s stable",
      "source /home/ubuntu/.rvm/scripts/rvm",
      "rvm install 3.2.2",                     # Example Ruby version
      "rvm use 3.2.2 --default",
      "ruby -v",
      "gem install bundler",
      "gem install puma"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = var.private_key
      host        = self.public_ip
    }
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "rails-db"
  allocated_storage      = 20
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  username               = "railsuser"
  password               = "railspassword"
  db_name                = "railsapp"
  publicly_accessible    = true
  skip_final_snapshot    = true
}

