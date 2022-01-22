terraform {
  backend "s3" {
    bucket = "noir-tfstate"
    key    = "example/prod/cicd/foobar_v1.0.0.tfstate"
    region = "ap-northeast-1"
  }
}