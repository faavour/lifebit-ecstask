resource "aws_s3_bucket" "lifebit_bucket" {
  bucket = "lifebit-test-bucket"
    tags = {
    Name        = "lifebit bucket"
    Environment = "Dev"
  }
}