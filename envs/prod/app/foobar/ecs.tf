resource "aws_ecs_cluster" "this" {
  name = "${local.name_prefix}-${local.service_name}"

  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT"
  ]

  tags = {
    Name = "${local.name_prefix}-${local.service_name}"
  }
}

// タスク定義
resource "aws_ecs_task_definition" "this" {
  // タスク定義の名前
  family = "${local.name_prefix}-${local.service_name}"

  // タスクロールのARNを指定
  task_role_arn = aws_iam_role.ecs_task.arn

  // containerで指定するDockerネットワーキングモードを指定
  network_mode = "awsvpc"

  // ECSの起動タイプ
  requires_compatibilities = [
    "FARGATE",
  ]

  // タスク実行ロールのARNを指定
  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  // 0.5GB, 0.25vCPU
  memory = "512"
  cpu    = "256"

  container_definitions = jsonencode(
    [
      {
        // コンテナの名前
        name  = "nginx"
        image = "${module.nginx.ecr_repository_this_repository_url}:latest"

        // トラフィックを送受信するポート番号
        portMappings = [
          {
            containerPort = 80
            protocol      = "tcp"
          }
        ]

        environment = []
        secrets     = []

        dependsOn = [
          {
            containerName = "php"
            condition     = "START"
          }
        ]

        // nginxとphp間の通信がUNIXドメインソケットなので(dockerfile見ると分かる)ECSでもそうなるように設定
        mountPoints = [
          {
            containerPath = "/var/run/php-fpm"
            sourceVolume  = "php-fpm-socket"
          }
        ]

        // contanierのログ設定
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/ecs/${local.name_prefix}-${(local.service_name)}/nginx"
            awslogs-region        = data.aws_region.current.id
            awslogs-stream-prefix = "ecs"
          }
        }
      },
      {
        name  = "php"
        image = "${module.php.ecr_repository_this_repository_url}:latest"

        portMappings = []

        environment = []
        secrets = [
          {
            name      = "APP_KEY"
            valueFrom = "/${local.system_name}/${local.env_name}/${local.service_name}/APP_KEY"
          }
        ]

        mountPoints = [
          {
            containerPath = "/var/run/php-fpm"
            sourceVolume  = "php-fpm-socket"
          }
        ]

        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = "/ecs/${local.name_prefix}-${(local.service_name)}/php"
            awslogs-region        = data.aws_region.current.id
            awslogs-stream-prefix = "ecs"
          }
        }
      }
    ]
  )

  volume {
    name = "php-fpm-socket"
  }

  tags = {
    Name = "${local.name_prefix}-${local.service_name}"
  }
}

// ECS service
resource "aws_ecs_service" "this" {
  // ECS serviceの名前
  name = "${local.name_prefix}-${local.service_name}"

  // 属するECSクラスターのARNを指定
  cluster = aws_ecs_cluster.this.arn

  // キャパシティプロバイダー戦略を指定
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    // 指定されたキャパシティープロバイダーで実行するタスクの最小限の数を指定
    // 今回はFARGATE＿SPOTのみの指定なので意味なし
    base              = 0
    // 指定されたキャパシティープロバイダーを使用する、起動済みタスクの総数に対する比率を指定
    // 今回はFARGATE＿SPOTのみの指定なので意味なし
    weight            = 1
  }
  // fargateのバージョン
  platform_version = "1.4.0"

  // ECSサービスで使用するタスク定義のARNを指定
  task_definition = aws_ecs_task_definition.this.arn

  // 起動させておくタスク数を指定
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  // 使用するロートバランサーの設定
  load_balancer {
    // ロードバランサーがトラフィックをフォワードするコンテナ名とポート番号を指定
    container_name   = "nginx"
    container_port   = 80
    target_group_arn = data.terraform_remote_state.routing_appfoobar_click.outputs.lb_target_group_foobar_arn
  }

  // 起動したタスクはALBのヘルスチェック、コンテナのヘルスチェック、Route53のヘルスチェックで異常が出ると、停止する。
  // health_check_grace_period_secondsでは、タスクの起動直後にこれらヘルスチェックで異常が出たとしても無視する猶予期間(秒数)を指定
  health_check_grace_period_seconds = 60

  network_configuration {
    // タスクにパブリックIPを割り当てるかどうか指定
    assign_public_ip = false
    security_groups = [
      data.terraform_remote_state.network_main.outputs.security_group_vpc_id
    ]
    subnets = [
      for s in data.terraform_remote_state.network_main.outputs.subnet_private : s.id
    ]
  }

  enable_execute_command = true

  tags = {
    Name = "${local.name_prefix}-${local.service_name}"
  }
}