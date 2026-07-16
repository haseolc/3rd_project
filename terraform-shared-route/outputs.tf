output "main_route_table_id" {
  description = "Main route table used by the shared public subnets"
  value       = data.aws_route_table.main.id
}

output "internet_gateway_id" {
  description = "Internet gateway used by the default internet route"
  value       = data.aws_internet_gateway.shared.id
}
