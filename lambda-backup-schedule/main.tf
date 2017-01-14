variable "lambda_arn" {    
}

variable "lambda_function_name" {    
}

variable "schedule_name" {
    default = "ebs-backup-midnight"
}

variable "schedule_expression" {
    default = "cron(15 0 * * ? *)"
}

variable "schedule_decription" {
    default = "Fires 15min past midnight (UTC) every day"
}

resource "aws_cloudwatch_event_rule" "every_midnight" {
    name = "${var.schedule_name}"
    description = "${var.schedule_decription}"
    schedule_expression = "${var.schedule_expression}"
}

resource "aws_cloudwatch_event_target" "schedule_ebs_backup_every_mightnight" {
    rule = "${aws_cloudwatch_event_rule.every_midnight.name}"
    target_id = "${var.schedule_name}-${var.lambda_function_name}"
    arn = "${var.lambda_arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_ebs_backup" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${var.lambda_function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every_midnight.arn}"
}