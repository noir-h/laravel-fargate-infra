# tfstateの保存場所
terraform {
  backend "s3" {
    bucket = "noir-tfstate"
    # 保存先のtfstateのfile名
    key    = "example/prod/app/foobar_v1.0.0.tfstate"
    region = "ap-northeast-1"
  }
}