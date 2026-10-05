# Primary provider — all regional app resources live in Stockholm.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
      Repo      = "CHMUROWNIA/demo"
    }
  }
}

# CloudFront requires its ACM certificate to be in us-east-1, regardless of
# where the rest of the infrastructure lives.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
      Repo      = "CHMUROWNIA/demo"
    }
  }
}
