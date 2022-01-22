// outputとして宣言された値を別のディレクトリから参照できる
output "s3_bucket_this_id" {
  value = aws_s3_bucket.this.id
}