provider "aws" {
  # version = "2.61.0"
  region = "ap-northeast-1"
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "test_role" {
  name               = "test_role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json # (not shown)

  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = ["ec2:DescribeInstances", "ec2:StartInstances", "ec2:StopInstances"]
          Effect = "Allow"
        Resource = "*" }
        , {
          "Effect" : "Allow",
          "Action" : [
            "ssm:CancelCommand",
            "ssm:GetCommandInvocation",
            "ssm:ListCommandInvocations",
            "ssm:ListCommands",
            "ssm:SendCommand",
            "ssm:GetAutomationExecution",
            "ssm:GetParameters",
            "ssm:StartAutomationExecution",
            "ssm:ListTagsForResource"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DescribeInstanceAttribute",
            "ec2:DescribeInstanceStatus",
            "ec2:DescribeInstances"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "lambda:InvokeFunction"
          ],
          "Resource" : [
            "arn:aws:lambda:*:*:function:SSM*",
            "arn:aws:lambda:*:*:function:*:SSM*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "states:DescribeExecution",
            "states:StartExecution"
          ],
          "Resource" : [
            "arn:aws:states:*:*:stateMachine:SSM*",
            "arn:aws:states:*:*:execution:SSM*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "resource-groups:ListGroups",
            "resource-groups:ListGroupResources",
            "resource-groups:GetGroupQuery"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "cloudformation:DescribeStacks",
            "cloudformation:ListStackResources"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "tag:GetResources"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "config:SelectResourceConfig"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "compute-optimizer:GetEC2InstanceRecommendations"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "support:DescribeTrustedAdvisorChecks",
            "support:DescribeTrustedAdvisorCheckSummaries",
            "support:DescribeTrustedAdvisorCheckResult"
          ],
          "Resource" : [
            "*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : "iam:PassRole",
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "iam:PassedToService" : [
                "ssm.amazonaws.com"
              ]
            }
          }
        }
      ]

    })
  }


}


resource "aws_ssm_maintenance_window" "window" {
  name     = "maintenance-window"
  schedule = "cron(07 11 ? * * *)"
  duration = 3
  cutoff   = 1
}

resource "aws_ssm_maintenance_window_target" "target1" {
  window_id     = aws_ssm_maintenance_window.window.id
  name          = "maintenance-window-target"
  description   = "This is a maintenance window target"
  resource_type = "INSTANCE"

  targets {
    key    = "InstanceIds"
    values = ["instanceid"]
  }
}

resource "aws_ssm_maintenance_window_task" "task" {
  window_id   = aws_ssm_maintenance_window.window.id
  name        = "maintenance-window-task"
  description = "This is a maintenance window task"
  task_type   = "AUTOMATION"
  task_arn    = "AWS-StopEC2Instance"
  priority    = 1
  service_role_arn = aws_iam_role.test_role.arn
  max_concurrency  = "2"
  max_errors       = "1"

  targets {
    key    = "InstanceIds"
    values = ["instanceid"]
  }

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "InstanceId"
        values = ["instanceid"]
      }
    }
  }
}

