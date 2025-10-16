terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
  }
}

locals {
  # The name used for the role and the db names. NOTE: They should be the same for the authentication to work.
  name = "bareau_${var.instance_name}"
}

resource "random_password" "the_password" {
  length           = 15
  special          = true
  override_special = "!#%&()-_=+<>"
}

resource "postgresql_role" "the_role" {
  name     = local.name
  password = random_password.the_password.result
  login    = true

  inherit                   = false
  create_database           = false
  superuser                 = false
  create_role               = false
  bypass_row_level_security = false
}

resource "postgresql_database" "the_db" {
  name     = local.name
  owner    = postgresql_role.the_role.name
  encoding = "UTF8"
  template = "template0"
}

# Equivalent of "GRANT ALL ON DATABASE <db> TO <role>;"
resource "postgresql_grant" "grant_all" {
  database    = postgresql_database.the_db.name
  object_type = "database"
  privileges  = ["CONNECT", "TEMPORARY", "CREATE"]
  role        = postgresql_role.the_role.name
}

# Equivalent of "GRANT ALL ON SCHEMA public TO <role>;"
resource "postgresql_grant" "grant_access_to_public_schema" {
  database    = postgresql_database.the_db.name
  schema      = "public"
  object_type = "schema"
  privileges  = ["CREATE", "USAGE"]
  role        = postgresql_role.the_role.name
}


# Ensuring other users don't have access to the public schema of this DB
resource "postgresql_grant" "revoke_public" {
  database    = postgresql_database.the_db.name
  role        = "public"
  schema      = "public"
  object_type = "database"
  privileges  = []

  depends_on = [
    postgresql_role.the_role
  ]
}

 
# REVOKE connect ON DATABASE postgres FROM PUBLIC;