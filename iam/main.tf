module "backup-role" {
    source = "ebs-backup-worker-role" 
}

module "backup-policy" {
    source = "ebs-snapshot-policy" 
}

resource "aws_iam_role_policy_attachment" "backup-snapshots" {
    role        = "${module.backup-role.role_name}"
    policy_arn  = "${module.backup-policy.policy_arn}"
}

output "backup_role" {
    value = "${module.backup-role.role_name}"
}

output "backup_role_arn" {
    value = "${module.backup-role.role_arn}"
}