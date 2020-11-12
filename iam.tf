data "aws_iam_policy_document" "ecs_assume_execution" {
  count = var.ecs_execution_role == "" ? 1 : 0

  statement {
    actions = [
      "sts:AssumeRole",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "fargate_execution" {
  count = var.ecs_execution_role == "" ? 1 : 0

  name               = "${var.name}-fargate-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_execution[0].json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "fargate_execution" {
  count = var.ecs_execution_role == "" ? length(var.execution_policies_arn) : 0

  role       = aws_iam_role.fargate_execution[0].id
  policy_arn = element(var.execution_policies_arn, count.index)
}
