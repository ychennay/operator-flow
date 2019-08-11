resource "aws_s3_bucket" "databricks_s3_bucket" {
  bucket = "databricks-operatorflow-bucket"
  tags = {
    operator = "databricks"
  }
}