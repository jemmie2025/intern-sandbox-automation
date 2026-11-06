variable "team" {
  description = "Unique identifier for the intern sandbox team."
  type        = string

  validation {
    condition     = can(regex("^lab-team-[0-9]{2}$", var.team))
    error_message = "Team must follow the format lab-team-03."
  }
}
