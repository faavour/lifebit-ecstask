output "loadbalancer_domain" {
    value = aws_lb.lifebit-lb.dns_name
}
output "ecs_service"{
    value = aws_ecs_service.lifebit-service.name
}
output "ecs_cluster"{
    value = aws_ecs_cluster.lifebit-cluster.name
}
output "vpc_id" {
    value = aws_vpc.lifebit-vpc.id
}
output "security_group_id" {
    value = aws_security_group.http_traffic.id
}
output "subnets" {
    value = aws_subnet.public[*].id
}