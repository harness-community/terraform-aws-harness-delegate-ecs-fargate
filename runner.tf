resource "aws_efs_file_system" "runner" {
  count = var.base64_runner_config != "" ? 1 : 0

  tags = {
    Name = "${var.name}-runner"
  }
}

resource "aws_efs_access_point" "runner" {
  count = var.base64_runner_config != "" ? 1 : 0

  file_system_id = aws_efs_file_system.runner[0].id
}

resource "aws_efs_mount_target" "runner" {
  count = var.base64_runner_config != "" ? length(var.subnets) : 0

  file_system_id = aws_efs_file_system.runner[0].id
  subnet_id      = var.subnets[count.index]
}

