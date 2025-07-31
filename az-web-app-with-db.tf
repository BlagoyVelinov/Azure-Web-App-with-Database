terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.28.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "47816c22-3a98-49bc-9643-fdfa42c426dd"
}

resource "random_integer" "randomInt" {
  min = 10000
  max = 99999
}

resource "azurerm_resource_group" "arg" {
  name     = "TaskBoardRg${random_integer.randomInt.result}"
  location = "North Europe"
}

resource "azurerm_service_plan" "asp" {
  name                = "TaskBoardServicePlan${random_integer.randomInt.result}"
  resource_group_name = azurerm_resource_group.arg.name
  location            = azurerm_resource_group.arg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

resource "azurerm_linux_web_app" "alwa" {
  name                = "TaskBoardApp${random_integer.randomInt.result}"
  resource_group_name = azurerm_resource_group.arg.name
  location            = azurerm_service_plan.asp.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }
  connection_string {
    name = "DefaultConnection"
    type = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.database.name};User ID=${azurerm_mssql_server.sqlserver.administrator_login};Password=${azurerm_mssql_server.sqlserver.administrator_login_password};Trusted_Connection=False; MultipleActiveResultSets=True;"
  }
}

resource "azurerm_mssql_server" "sqlserver" {
  name                         = "task-board-sqlserver-${random_integer.randomInt.result}"
  resource_group_name          = azurerm_resource_group.arg.name
  location                     = azurerm_resource_group.arg.location
  version                      = "12.0"
  administrator_login          = "missadministrator"
  administrator_login_password = "thisIsKat11"
}

resource "azurerm_mssql_database" "database" {
  name         = "taskboard-database-${random_integer.randomInt.result}"
  server_id    = azurerm_mssql_server.sqlserver.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "S0"
  zone_redundant = false
  storage_account_type = "Zone"
  geo_backup_enabled = false
}

resource "azurerm_mssql_firewall_rule" "firewall" {
  name             = "FirewallRule1"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_app_service_source_control" "aassc" {
  app_id   = azurerm_linux_web_app.alwa.id
  repo_url = "https://github.com/BlagoyVelinov/Azure-Web-App-with-Database"
  branch   = "main"
  use_manual_integration = true
}
