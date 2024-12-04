variable "excluded_az" {
  default = "ap-south-1c"
}
variable "cidr_block" {
  default = "10.0.0.0/16"
}
variable "keyname" {
  default = "ecskeypair"
}
variable "instance_type" {
  default = "t2.medium"
}
variable "availability_zone" {
  default = "ap-south-1a"
}
variable "ebs_size" {
  default = 1
}
variable "image_id" {
  default = "848417356303.dkr.ecr.ap-south-1.amazonaws.com/shorturl:latest"
}
variable "ami_id" {
  default = "ami-0e45c8a260a13d2b2"
}

variable "public_nacl" {
  type=list(object({
    rule_number=number
    action=string
    from_port=number
    to_port=number
    protocol=string
    cidr_block=string
    egress=bool
  }))
  default = [ 
  {
  rule_number = 50
  action="allow"
  from_port = 1024
  to_port = 3388
  protocol = "6"
  cidr_block =  "0.0.0.0/0" 
  egress = false
  },
  {
  rule_number = 100
  action="allow"
  from_port = 1024
  to_port = 3388
  protocol = "17"
  cidr_block =  "0.0.0.0/0" 
  egress = false
  },
  {
  rule_number = 150
  action="allow"
  from_port = 3390
  to_port = 65535
  protocol = "6"
  cidr_block =  "0.0.0.0/0" 
  egress = false
  },
  {
  rule_number = 200
  action="allow"
  from_port = 3390
  to_port = 65535
  protocol = "17"
  cidr_block =  "0.0.0.0/0" 
  egress = false
  },
  {
    rule_number = 250
    action = "allow"
    from_port = 80
    to_port = 80
    cidr_block =  "0.0.0.0/0" 
    protocol = "6"
    egress = false
  },
  {
    rule_number = 300
    action = "allow"
    from_port = 80
    to_port = 80
    cidr_block =  "0.0.0.0/0" 
    protocol = "17"
    egress = false
  },
  {
    rule_number = 350
    action = "allow"
    from_port = 443
    to_port = 443
    cidr_block =  "0.0.0.0/0" 
    protocol = "6"
    egress = false
  },
  {
    rule_number = 400
    action = "allow"
    from_port = 443
    to_port = 443
    cidr_block =  "0.0.0.0/0" 
    protocol = "17"
    egress = false
  },
  {
    rule_number = 450
    action = "allow"
    from_port = 587
    to_port = 587
    cidr_block =  "0.0.0.0/0" 
    protocol = "tcp"
    egress = false
  },{
    rule_number = 500
    action = "allow"
    from_port = 22
    to_port = 22
    cidr_block =  "101.0.62.143/32" 
    protocol = "tcp"
    egress = false
  },
  {
    rule_number = 550
    action = "allow"
    from_port = 3389
    to_port = 3389
    cidr_block =  "101.0.62.143/32"  
    protocol = "tcp"
    egress = false
  },{
    rule_number = 600
    action = "allow"
    from_port = 22
    to_port = 22
    cidr_block =  "10.0.0.0/16"
    protocol = "tcp"
    egress = false
  },{
    rule_number = 650
    action = "allow"
    from_port = 3389
    to_port = 3389
    cidr_block =  "10.0.0.0/16"
    protocol = "tcp"
    egress = false
  },
  {
    rule_number = 50
    action = "allow"
    from_port = 1024
    to_port = 65535
    cidr_block = "0.0.0.0/0"
    protocol = "6"
    egress = true
  },{
    rule_number = 100
    action = "allow"
    from_port = 1024
    to_port = 65535
    cidr_block = "0.0.0.0/0"
    protocol = "17"
    egress = true
  },{
    rule_number = 150
    action = "allow"
    from_port = 80
    to_port = 80
    cidr_block = "0.0.0.0/0"
    protocol = "tcp"
    egress = true
  },{
    rule_number = 200
    action = "allow"
    from_port = 443
    to_port = 443
    cidr_block = "0.0.0.0/0"
    protocol = "tcp"
    egress = true
  },{
    rule_number = 250
    action = "allow"
    from_port = 22
    to_port = 22
    cidr_block =  "101.0.62.143/32" 
    protocol = "tcp"
    egress = true
  },{
    rule_number = 300
    action = "allow"
    from_port = 3389
    to_port = 3389
    cidr_block =  "101.0.62.143/32" 
    protocol = "tcp"
    egress = true
  },{
    rule_number = 350
    action = "allow"
    from_port = 22
    to_port = 22
    cidr_block =  "10.0.0.0/16" 
    protocol = "tcp"
    egress = true
  },{
    rule_number = 400
    action = "allow"
    from_port = 3389
    to_port = 3389
    cidr_block =  "10.0.0.0/16" 
    protocol = "tcp"
    egress = true
  },{
    rule_number = 450
    action = "allow"
    from_port = 587
    to_port = 587
    cidr_block =  "0.0.0.0/0" 
    protocol = "tcp"
    egress = true
  } ]
}

variable "private_nacl_rules" {
  type = list(object({
    rule_number = number
    action      = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_block  = string
    egress      = bool
  }))
  default = [
    # Ingress Rule: Allow all inbound traffic from within the VPC
    {
      rule_number = 100
      from_port   = 80
      to_port     = 80
      protocol    = "6"      # "-1" means all protocols
      action      = "allow"
      cidr_block  = "0.0.0.0/0" 
      egress      = false
      action = "allow"
    },
    # Ingress Rule: Allow return traffic from the internet (Ephemeral Ports)
    {
      rule_number = 150
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      action      = "allow"
      cidr_block  = "0.0.0.0/0" 
      egress      = false
      action = "allow"
    },
    {
      rule_number = 200
      from_port   = 1024
      to_port     = 3388
      protocol    = "tcp"
      action      = "allow"
      cidr_block  = "0.0.0.0/0" 
      egress      = false
      action = "allow"
    },
    {
      rule_number = 250
      from_port   = 3390
      to_port     = 65535
      protocol    = "tcp"
      action      = "allow"
      cidr_block  = "0.0.0.0/0" 
      egress      = false
      action = "allow"
    },
    {
      rule_number = 300
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      action      = "allow"
      cidr_block  = "10.0.0.0/16" 
      egress      = false
      action = "allow"
    },
    {
      rule_number = 350
      from_port   = 0
      to_port     = 65535
      protocol    = "udp"
      action      = "allow"
      cidr_block  = "10.0.0.0/16" 
      egress      = false
      action = "allow"
    },
    {
      rule_number = 400
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      action      = "allow"
      cidr_block  = "101.0.62.143/32" 
      egress      = false
      action = "allow"
    },
    {
      rule_number = 450
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      action      = "allow"
      cidr_block  = "101.0.62.143/32" 
      egress      = false
      action = "allow"
    },
    {
      rule_number = 500
      from_port   = 1024
      to_port     = 3388
      protocol    = "tcp"
      action      = "allow"
      cidr_block  = "0.0.0.0/0" 
      egress      = false
      action = "allow"
    },
    {
      rule_number = 550
      from_port   = 3390
      to_port     = 65535
      protocol    = "tcp"
      action      = "allow"
      cidr_block  = "0.0.0.0/0" 
      egress      = false
      action = "allow"
    },
    # Egress Rule: Allow all outbound traffic to the internet
    {
      rule_number = 100
      from_port   = 80
      to_port     = 80
      protocol    = "6"
      action      = "allow"
      cidr_block  = "0.0.0.0/0"
      egress      = true
      action = "allow"
    },
    {
      rule_number = 150
      from_port   = 443
      to_port     = 443
      protocol    = "6"
      action      = "allow"
      cidr_block  = "0.0.0.0/0"
      egress      = true
      action = "allow"
    },
    {
      rule_number = 200
      from_port   = 0
      to_port     = 65535
      protocol    = "6"
      action      = "allow"
      cidr_block  = "10.0.0.0/16"
      egress      = true
    },
    {
      rule_number = 250
      from_port   = 0
      to_port     = 65535
      protocol    = "17"
      action      = "allow"
      cidr_block  = "10.0.0.0/16"
      egress      = true
      action = "allow"
    },
    {
      rule_number = 300
      from_port   = 22
      to_port     = 22
      protocol    = "6"
      action      = "allow"
      cidr_block  = "101.0.62.143/32"
      egress      = true
      action = "allow"
    },
    {
      rule_number = 350
      from_port   = 3389
      to_port     = 3389
      protocol    = "6"
      action      = "allow"
      cidr_block  = "101.0.62.143/32"
      egress      = true
      action = "allow"
    }
  ]
}
variable "dbcreds_name" {
  default = "prod/db/postgres"
}
variable "googleauth_name" {
  default = "prod/googleOauth"
}