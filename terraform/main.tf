provider "aws" {
  region = "us-east-1"
}

variable "private_key" {}
resource "aws_key_pair" "deployer" {
  key_name   = "rails-key"
}

resource "aws_instance" "app" {
  ami           = "ami-007855ac798b5175e" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

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
      user        = "ec2-user"
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

