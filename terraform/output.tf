output "loadbalancer_domain" {
    value = aws_lb.lifebit-lb.dns_name
}
output "ecs_service"{
    value = aws_ecs_service.lifebit-service.name
}