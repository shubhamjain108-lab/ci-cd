provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "deployer" {
  key_name   = "rails-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

resource "aws_instance" "app" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  tags = {
    Name = "RailsApp"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install git -y",
      "sudo yum install -y gcc-c++ patch readline readline-devel zlib zlib-devel git curl",
      "gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3",
      "curl -sSL https://get.rvm.io | bash -s stable",
      "source /home/ec2-user/.rvm/scripts/rvm",
      "rvm install 3.2.2",
      "gem install bundler",
      "gem install puma"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
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

