

provider "aws" {
    region = "ap-south-1"

}
resource "aws_vpc" "myvpc" {
    cidr_block = "10.0.0.0/16"
  
}
resource "aws_subnet" "private1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "0.0.1.0/24"
    availability_zone = "ap-south-1a"
  
}
resource "aws_subnet" "private2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "0.0.2.0/24"
    availability_zone = "ap-south-1b"
}
resource "aws_subnet" "public1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "0.0.3.0/24"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true
}
resource "aws_subnet" "public2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "0.0.4.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = true
}
resource "aws_internet_gateway" "ing" {
    vpc_id = aws_vpc.myvpc.id
  
}
resource "aws_route_table" "t1" {
    vpc_id = aws_vpc.myvpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.ing.id
    }
   
}
resource "aws_route_table_association" "rt1" {
    subnet_id = aws_subnet.public1.id
    route_table_id = aws_route_table.t1.id
  
}

resource "aws_eip" "eip1" {
  
}
resource "aws_eip" "eip2" {
  
}
resource "aws_nat_gateway" "p1" {
    subnet_id = aws_subnet.private1.id
    allocation_id = aws_eip.eip1.id
     
}
resource "aws_nat_gateway" "p2" {
    subnet_id = aws_subnet.private2.id
    allocation_id = aws_eip.eip2.id
  
}
  

resource "aws_route_table" "t2" {
    vpc_id = aws_vpc.myvpc.id
    route {
        cidr_block = "0.0.1.0/24"
        nat_gateway_id = aws_nat_gateway.p1.id
    }
}

resource "aws_route_table_association" "rt2" {
    route_table_id = aws_route_table.t2.id
    subnet_id = aws_subnet.private1.id
  
}

resource "aws_route_table" "t3" {
    vpc_id = aws_vpc.myvpc.id
    route {
        cidr_block = "0.0.2.0/24"
        nat_gateway_id = aws_nat_gateway.p2.id
    }
  
}
resource "aws_route_table_association" "rt3" {
    route_table_id = aws_route_table.t3.id
    subnet_id = aws_subnet.private2.id
  
}
resource "aws_security_group" "sq1" {
    vpc_id = aws_vpc.myvpc.id
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 5000
        to_port = 5000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"  
        cidr_blocks = ["0.0.0.0/0"]
         }
    
}
resource "aws_lb" "my-lb" {
    name = "my-lb"
    internal = false 
    load_balancer_type = "application"
    security_groups = [aws_security_group.sq1.id]
    subnets = [aws_subnet.private1.id , aws_subnet.private2.id]
  
}
resource "aws_lb_target_group" "tg" {
    name = "tg"
    port = 5000
    protocol = "HTTP"
    vpc_id = aws_vpc.myvpc.id
    health_check {
      path = "/"
      port = "traffic-port"
    }
  
}
resource "aws_lb_target_group_attachment" "tga" {
    target_group_arn = aws_lb_target_group.tg.arn
    target_id = aws_instance.in1.id
    port = 5000

}
resource "aws_lb_listener" "lbl" {
    load_balancer_arn = aws_lb.my-lb.arn
    port = 5000
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.tg.arn

    }
  
}


resource "aws_instance" "in1" {
    ami = "ami-0f58b397bc5c1f2e8"
    instance_type = "t2-medium"
    subnet_id = aws_subnet.private1.id
    security_groups = [ aws_security_group.sq1.id ]
    provisioner "remote-exec" {
        inline = [ 
            "sudo apt-get update -y",
            "sudo apt-get install docker-compose -y",
            "sudo git clone https://github.com/rahulkatrap/two-tier-app-deploy.git" ,
            "cd two-tier-app-deploy/ ",
            "sudo docker-compose up"
         ]
      
    }
  
}
resource "aws_instance" "inw" {
    ami = "ami-0f58b397bc5c1f2e8"
    instance_type = "t2-micro"
    subnet_id = aws_subnet.private2.id
    security_groups = [ aws_security_group.sq1.id ]
  
}