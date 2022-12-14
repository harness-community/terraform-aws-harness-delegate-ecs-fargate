resource "aws_efs_file_system" "runner" {
  count = local.runner_config != "" ? 1 : 0

  encrypted  = true
  kms_key_id = var.kms_key_id

  tags = {
    Name = "${var.name}-runner"
  }
}

resource "aws_efs_access_point" "runner" {
  count = local.runner_config != "" ? 1 : 0

  file_system_id = aws_efs_file_system.runner[0].id
}

resource "aws_efs_mount_target" "runner" {
  count = local.runner_config != "" ? length(var.subnets) : 0

  file_system_id = aws_efs_file_system.runner[0].id
  subnet_id      = var.subnets[count.index]
}

