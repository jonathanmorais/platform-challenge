data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_iam_role" "service" {
  name = "ecsTaskRole-${local.service_id}"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF


  tags = var.tags
}


resource "aws_iam_role_policy" "service" {
  name   = "ecsTaskRolePolicy-${local.service_id}"
  role   = aws_iam_role.service.id
  policy = file("${path.cwd}/${var.service_policy}")
}