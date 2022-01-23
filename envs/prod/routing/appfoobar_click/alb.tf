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
  ssl_policy = "ELBSecurityPolicy-2016-08"

  default_action {
    // テスト用
    # type = "fixed-response"

    # fixed_response {
    #   content_type = "text/plain"
    #   message_body = "Fixed response content"
    #   status_code  = "200"
    # }

    type = "forward"

    target_group_arn = aws_lb_target_group.foobar.arn
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

resource "aws_lb_target_group" "foobar" {
  name = "${local.name_prefix}-foobar"

  // ターゲットを解除する(ALBから切り離す)前に、ALBが待機する時間を指定する
  deregistration_delay = 60
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = data.terraform_remote_state.network_main.outputs.vpc_this_id
  // ALBはヘルスチェックとして、ターゲットに定期的にリクエストを送信する。その設定 
  health_check {
    // 異常なターゲットが正常であると見なされるまでに、必要なヘルスチェックの連続成功回数
    healthy_threshold = 2
    // ヘルスチェックの間隔を秒で指定
    interval = 30
    // どんなステータスコードが返ってきたら正常とみなすかを指定
    matcher = 200
    // ヘルスチェックで使用するpath
    path = "/"
    // ヘルスチェックで使用するポート番号を指定。"traffic-port"を指定すると、ターゲットがALBからのトラフィックを受信するポートが、ヘルスチェックでも使用される
    port = "traffic-port"
    // ヘルスチェックで使用するprotocl
    protocol = "HTTP"
    // ここで指定した秒数の間、ターゲットからのレスポンスがないと、ヘルスチェックが失敗とみなされる
    timeout = 5
    // ターゲットが異常であると見なされるまでに、必要なヘルスチェックの連続失敗回数
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${local.name_prefix}-foobar"
  }
}