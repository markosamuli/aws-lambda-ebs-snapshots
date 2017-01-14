module "iam" {
    source = "iam"
}

module "lambda-backup-worker" {
    source  = "lambda-backup-worker"
    role    = "${module.iam.backup_role_arn}"
}

module "lambda-backup-schedule" {
    source                  = "lambda-backup-schedule"
    lambda_arn              = "${module.lambda-backup-worker.lambda_arn}"
    lambda_function_name    = "${module.lambda-backup-worker.lambda_function_name}"
}

output "backup_lambra_function" {
    value = "${module.lambda-backup-worker.lambda_function_name}"
}