variable "name" {
    default = "schedule-ebs-backup-snapshots"
}

variable "role" {

}

provider "archive" {
}

data "archive_file" "lambda_zip" {
    type        = "zip"
    source_dir  = "${path.module}/src"
    output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "backup-worker" {
    filename = "${path.module}/lambda.zip"
    function_name = "${var.name}"
    role = "${var.role}"
    handler = "backup.lambda_handler"
    runtime = "python2.7"
    description = "Schedule EBS backup snaphots (managed by Terraform)" 
    source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
}

output "lambda_function_name" {
    value = "${aws_lambda_function.backup-worker.function_name}"
}

output "lambda_arn" {
    value = "${aws_lambda_function.backup-worker.arn}"
}