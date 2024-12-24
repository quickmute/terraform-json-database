##list
output "ous" {
  value = local.ous
}

##list
output "accounts" {
  value = local.accounts
}

##list
output "policies" {
  value = local.policies
}

##MAP
##Key is a String (account name)
##Value is a Map
output "accounts_content" {
  value = local.accounts_content
}

## This is a duplicate to account_name until we move away from this name
##MAP
##Key is a String (account alias)
##Value is a String (account name)
output "accounts_alias" {
  value = local.accounts_name
}
##MAP
##Key is a String (account alias)
##Value is a String (account name)
output "accounts_name" {
  value = local.accounts_name
}

##THIS CAN BE REMOVED AFTER WE VERIFIED THAT IT'S NOT BEING USED
##MAP
##Key is a String (account alias)
##Value is a String (account type)
output "accounts_type" {
  value = local.accounts_type
}

##MAP
##Key is a String (account_type)
##Value is a list (account aliases)
output "accounts_type_grouped" {
  value = local.accounts_type_grouped
}

##MAP
##Key is a String (account alias)
##Value is a String (account type)
output "accounts_subtype" {
  value = local.accounts_subtype
}

##MAP
##Key is a String (account_type)
##Value is a list (account aliases)
output "accounts_subtype_grouped" {
  value = local.accounts_subtype_grouped
}

##MAP
##Key is a String (account alias)
##Value is a String (account environment)
output "accounts_env" {
  value = local.accounts_env
}

##MAP
##Key is a String (account_environment)
##Value is a list (account aliases)
output "accounts_env_grouped" {
  value = local.accounts_env_grouped
}

##MAP
##Key is a String (account alias)
##Value is a String (app name)
output "application_name" {
  value = local.application_name
}

##MAP
##Key is a String (app name)
##Value is a list (account aliases)
output "accounts_app_name_grouped" {
  value = local.accounts_app_name_grouped
}

output "accounts_groups_grouped" {
  value = local.accounts_groups_grouped
}


##MAP
##Key is a String (account alias)
##Value is a String (app type)
output "application_type" {
  value = local.application_type
}

##MAP
##Key is a String (app type)
##Value is a list (account aliases)
output "accounts_app_type_grouped" {
  value = local.accounts_app_type_grouped
}

##MAP
##Key is a String (account number)
##Value is a String (account_name)
output "accounts_num_to_name" {
  value = local.accounts_num_to_name
}

##MAP
##Key is a String (account number)
##Value is a String (account_status)
output "accounts_num_to_status" {
  value = local.accounts_num_to_status
}

##MAP
##Key is a String (account alias)
##Value is a String (account_status)
output "accounts_alias_to_status" {
  value = local.accounts_alias_to_status
}

##MAP
##Key is a String (account_name)
##Value is a list (account number)
output "accounts_numbers" {
  value = local.accounts_number
}

##LIST
##Just account numbers
output "accounts_numbers_only" {
  value = local.accounts_num_only
}

##THIS CAN BE REMOVED AFTER WE VERIFIED THAT IT'S NOT BEING USED
##MAP
##Key is a String (account alias)
##Value is a String (account vpc_cidr)
output "accounts_vpc_cidr" {
  value = local.accounts_vpc_cidr
}

##MAP
##Key is a String (account number)
##Value is a MAP with name, alias, application_type, account_subtype and vpc_cidr keys
output "accounts_number_detail" {
  value = local.accounts_number_detail
}

##MAP
##Key is a String (account alias)
##Value is a MAP with name, number, and vpc_cidr keys
output "accounts_alias_detail" {
  value = local.accounts_alias_detail
}

output "accounts_sso_groups" {
  value = local.accounts_aws_sso
}

output "account_alternate_contacts" {
  description = "Map of alternative contacts with Account Name as key"
  value       = local.account_alternate_contacts
}

output "account_alternate_contacts_billing" {
  description = "Map of alternative contacts with Billing Contact as key and list of accounts that they manage"
  value       = local.account_alternate_contacts_billing_grouped
}

output "account_alternate_contacts_operations" {
  description = "Map of alternative contacts with operations Contact as key and list of accounts that they manage"
  value       = local.account_alternate_contacts_operations_grouped
}

output "account_alternate_contacts_security" {
  description = "Map of alternative contacts with security Contact as key and list of accounts that they manage"
  value       = local.account_alternate_contacts_security_grouped
}

output "sso_permission_sets" {
  value = local.sso_permission_sets_details
}

output "sso_permset_poli_list" {
  value = local.sso_permset_poli_list
}

output "sso_permset_line_list" {
  value = local.sso_permset_line_list
}

output "sso_flatten_verified" {
  value = local.sso_pancake_batch
}

output "sso_groups" {
  value = local.sso_groups_unique
}

output "sso_groups_based" {
  value = local.sso_groups_based
}

output "unique_environment_validation" {
  value = local.accounts_groups_to_app_name_to_env
}

output "all_vpc_cidrs" {
  value = local.all_vpc_cidrs
}

output "accounts_sso_apps" {
  value = local.accounts_aws_sso_app
}

output "sso_app_groups" {
  value = local.accounts_aws_sso_app_groups
}