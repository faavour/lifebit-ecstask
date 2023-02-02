output "loadbalancer_domain" {
    value = aws_lb.lifebit-lb.dns_name
}