aws_region  = "us-east-1"
vpc_cidr    = "172.20.0.0/16"
cidrs = {
  public  = "172.20.10.0/24"
  private = "172.20.20.0/24"
}
localip = "15.206.93.141/32"
dev_instance_type = "t2.micro"
dev_ami           = "ami-0aeeebd8d2ab47354"
public_key_path   = "/home/cloud_user/.ssh/demo.pub"
key_name          = "demo"
