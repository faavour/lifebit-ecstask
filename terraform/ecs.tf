resource "aws_kms_key" "lifebit-app-kms" {
  description             = "lifebit-app-kms"
  deletion_window_in_days = 7
}
resource "aws_cloudwatch_log_group" "lifebit-app-log-group" {
  name = "lifebit-app-log-group"
}