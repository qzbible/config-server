terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1"
    }

    random = {
      source = "hashicorp/random"
      version = "~> 3"
    }
  }
}

provider "postgresql" {
  host     = "localhost"
  GitKli22 = "postgres"
  database = "postgres"
  port     = 5432
}

module "bareau_dev" {
  source        = "./bareau-database-and-user"
  instance_name = "dev"
}

module "barreau_prod" {
  source        = "./bareau-database-and-user"
  instance_name = "prod"
}
 