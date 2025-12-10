resource "aws_acm_certificate" "ssl_cert" {
  domain_name = "buynsell.work.gd"
  validation_method = "DNS"
  subject_alternative_names = ["www.buynsell.work.gd"]
}