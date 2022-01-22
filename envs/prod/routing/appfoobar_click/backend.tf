terraform {
  backend "s3" {
    bucket = "noir-tfstate"
    key    = "example/prod/routing/appfoobar_click_v1.0.0.tfstate"
    region = "ap-northeast-1"
  }
}