data "aws_iam_policy_document" "snapshot" {
    statement {
        sid = "1"
        actions = [
            "logs:*",
        ]
        resources = [
            "arn:aws:logs:*:*:*",
        ]
    }
    statement {
        sid = "2"
        actions = [
            "ec2:Describe*",
        ]
        resources = [
            "*",
        ]
    }
    statement {
        sid = "3"
        actions = [
            "ec2:CreateSnapshot",
            "ec2:ModifySnapshotAttribute",
            "ec2:ResetSnapshotAttribute"
        ]
        resources = [
            "*",
        ]
    }
    statement {
        sid = "4"
        actions = [
            "ec2:CreateTags",
        ]
        resources = [
            "*",
        ]
    }
}

variable "name" {
    default = "TakeBackupSnapshots"
}

resource "aws_iam_policy" "snapshot" {
    name = "${var.name}"
    path = "/"
    policy = "${data.aws_iam_policy_document.snapshot.json}"
}

output "policy_arn" {
    value = "${aws_iam_policy.snapshot.arn}"
}