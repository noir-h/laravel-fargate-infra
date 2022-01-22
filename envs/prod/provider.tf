/* -----------------------------
 - providerの設定
 - シンボリックリンクでterraformの実行する場所で読み取れるようにする
 ----------------------------- */
provider "aws" {
  region = "ap-northeast-1"
  # profile = ""

  default_tags {
    tags = {
      Env    = "prod"
      System = "example"
    }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.42.0"
    }
  }

  # terraformのversion
  required_version = "1.0.0"
}