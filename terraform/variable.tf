data "aws_availability_zones" "availabity_zones" {
  state = "available"
}

locals {
    azs = slice(data.aws_availability_zones.availabity_zones.names, 0, 2)

    subnets = {
        public1 = {
            cidr_block = cidrsubnet(aws_vpc.watchtower.cidr_block, 8, 0)
            is_public = true
            availabity_zones = local.azs[0]
        },

        public2 = {
            cidr_block = cidrsubnet(aws_vpc.watchtower.cidr_block, 8, 1)
            is_public = true
            availabity_zones = local.azs[1]
        }
    }
}

output "image_registry_url" {
  value = aws_ecr_repository.watchtower_repository.repository_url
}
