# Monthly cost budget for the whole organization. It only e-mails; it never
# stops anything. Budgets without actions are free.

locals {
  billing = local.lz_config.org.billing
}

resource "aws_budgets_budget" "org" {
  name         = local.billing.budget_name
  budget_type  = "COST"
  limit_amount = format("%.2f", local.billing.budget_usd)
  limit_unit   = local.billing.currency
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = local.billing.alert_at
    content {
      comparison_operator        = "GREATER_THAN"
      notification_type          = "ACTUAL"
      threshold                  = notification.value
      threshold_type             = "PERCENTAGE"
      subscriber_email_addresses = [local.billing.email]
    }
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "FORECASTED"
    threshold                  = local.billing.forecast_alert_at
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = [local.billing.email]
  }
}
