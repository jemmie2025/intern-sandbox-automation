locals {
  team_name = var.team

  postgres_name = replace(var.team, "-", "_")
  nomad_namespace = var.team
  s3_bucket       = var.team

  wireguard_interface = "wg0"
}
