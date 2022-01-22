data "aws_route53_zone" "this" {
  name = "noir-h.click"
}

resource "aws_route53_record" "certificate_validation" {
  // ACMで発行した証明書のドメインの所有権をDNSで検証する
  // Route53で証明用のCNAMEを登録
  for_each = {
    for dvo in aws_acm_certificate.root.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  name    = each.value.name
  records = [each.value.record]
  ttl     = 60
  type    = each.value.type
  zone_id = data.aws_route53_zone.this.id
}

resource "aws_route53_record" "root_a" {
  count = var.enable_alb ? 1 : 0

  name    = data.aws_route53_zone.this.name
  type    = "A"
  zone_id = data.aws_route53_zone.this.zone_id

  alias {
    evaluate_target_health = true
    // dns_nameはALBのDNS名
    name                   = aws_lb.this[0].dns_name
    zone_id                = aws_lb.this[0].zone_id
  }
}