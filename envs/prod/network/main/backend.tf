terraform {
  backend "s3" {
    bucket = "noir-tfstate"
    key    = "example/prod/network/foobar_v1.0.0.tfstate"
    region = "ap-northeast-1"
  }
}