variable "instance_name" {
  type        = string
  description = "Name of the Barreau instance"

  validation {
    condition     = can(regex("^[_a-zA-Z][_a-zA-Z0-9]*$", var.instance_name))
    error_message = "Instance name must start with a letter or underscore and contain only letters, digits, and underscores."
  }
}
