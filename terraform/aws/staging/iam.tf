resource "aws_iam_role" "ecs_task_execution_role" {
  name = "lornu-ecs-task-execution-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Optional: Add policy to read secrets if defined
resource "aws_iam_policy" "secrets_access" {
  count       = var.secret_gemini_api_key_arn != "" ? 1 : 0
  name        = "lornu-secrets-access-${var.environment}"
  description = "Allow ECS tasks to read specific secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.secret_gemini_api_key_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_access_attach" {
  count      = var.secret_gemini_api_key_arn != "" ? 1 : 0
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access[0].arn
}
