variable "name" {
    default = "ebs-backup-worker"
}

resource "aws_iam_role" "lambda" {
    name = "${var.name}"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

output "role_name" {
    value = "${aws_iam_role.lambda.name}"
}

output "role_arn" {
    value = "${aws_iam_role.lambda.arn}"
}