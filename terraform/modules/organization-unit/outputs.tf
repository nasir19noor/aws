output "detail" {
  description = "id, arn and name of the OU"
  value = {
    id   = aws_organizations_organizational_unit.this.id
    arn  = aws_organizations_organizational_unit.this.arn
    name = aws_organizations_organizational_unit.this.name
  }
}
