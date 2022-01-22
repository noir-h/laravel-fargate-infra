resource "aws_lb" "this" {
// countの数だけリソースが作られる
  count = var.enable_alb ? 1 : 0

  name = "${local.name_prefix}-appfoobar-click"

// 内部向けか、外部向けか
  internal           = false
  load_balancer_type = "application"

// accsesslogの保存場所指定
  access_logs {
    bucket  = data.terraform_remote_state.log_alb.outputs.s3_bucket_this_id
    enabled = true
    prefix  = "appfoobar-click"
  }

  security_groups = [
    data.terraform_remote_state.network_main.outputs.security_group_web_id,
    data.terraform_remote_state.network_main.outputs.security_group_vpc_id
  ]

// ALBが属するサブネットのIDをlist形式で指定する
  subnets = [
    for s in data.terraform_remote_state.network_main.outputs.subnet_public : s.id
  ]

  tags = {
    Name = "${local.name_prefix}-appfoobar-click"
  }
}

resource "aws_lb_listener" "https" {
  count = var.enable_alb ? 1 : 0

// protocolに「"HTTPS"」を指定した場合は、証明書のARNを指定します。 
  certificate_arn   = aws_acm_certificate.root.arn
  load_balancer_arn = aws_lb.this[0].arn
  port              = "443"
  protocol          = "HTTPS"
  // defaultを明示的に指定してるだけ
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "redirect_http_to_https" {
  count = var.enable_alb ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}