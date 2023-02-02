output "loadbalancer_domain" {
    value = aws_lb.lifebit-lb.dns_name
}
output "ecs_service"{
    value = aws_ecs_service.lifebit-service.name
}
output "ecs_cluster"{
    value = aws_ecs_cluster.lifebit-cluster.name
}