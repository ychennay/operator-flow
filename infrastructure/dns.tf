data aws_route53_zone "hosted_zone" {
  name = "ychennay.com"
}


resource "aws_route53_record" "dns_record" {
  zone_id = data.aws_route53_zone.hosted_zone.id
  name    = "api.ychennay.com"
  type    = "A"
  ttl     = "300"
  records = [
  "${aws_eip.lb.public_ip}"]
}