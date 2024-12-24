##Pull all files from this local location
locals {
  ##This is the top level where account jsons are kept
  accountnum_prefix = "accounts"
  ##This is the top level folder where the structure will be kept
  structure_prefix = "structure"
  ##This is where permission sets are kept
  permset_prefix = "permission_sets"
  ##This is the common ending of all account jsons
  account_file = ".acct.json"
  ##this is the commone ending of all policy jsons (placeholder)
  policy_file = ".pol.json"
  ##this is the commone file that designate what is an OU
  ou_file = "ou.txt"
  ##this is the complete list of files pulled down
  structure_files  = fileset(local.structure_prefix, "**/*")
  accountnum_files = fileset(local.accountnum_prefix, "*.json")
  permset_files    = fileset(local.permset_prefix, "*.json")
}

locals {
  ##get all the account name to number mapping. This can be found under accountnum_prefix folder. 
  ## Each file contains a single account information. This makes it easier to automate 
  ## dropping file and doing a PR
  accountnum_mapping = {
    for filename in local.accountnum_files :
    lookup(jsondecode(file(format("%s/%s", local.accountnum_prefix, filename))), "accountname", "") => lookup(jsondecode(file(format("%s/%s", local.accountnum_prefix, filename))), "accountnum", "")
    if lookup(jsondecode(file(format("%s/%s", local.accountnum_prefix, filename))), "accountname", "") != ""
  }
  ##This is the contents of all account json files. This is a map where the key is the account name.
  ## Set default keys for each account (email, alias, DefaultCostCenter, and parent_path), these will be overridden by whatever is provided in the JSON. 
  ## This was originally part of org-accounts module, but moved it here instead.
  ## TRY function in the second IF condition is required since the file found may NOT be a JSON type and without TRY this will error out
  accounts_content = {
    for acct in local.structure_files :
    jsondecode(file(format("%s/%s", local.structure_prefix, acct))).name => merge(
      {
        ## Define defaults for these, if they exist in the account metadata json file then it'll get overwritten
        ## This assumes that name is always provided, as it should be!
        "email"             = format("IT-AWS-%s@squirrel.fake", jsondecode(file(format("%s/%s", local.structure_prefix, acct))).name)
        "alias"             = format("%s-%s", "squirrel", jsondecode(file(format("%s/%s", local.structure_prefix, acct))).name)
        "vpc_name"          = format("%s_vpc", jsondecode(file(format("%s/%s", local.structure_prefix, acct))).name)
        "parent_path"       = format("/%s", dirname(acct))
        "alternate_contacts" = {
          "BILLING" = {
            "email" = "squirrel@squirrel.fake",
            "name"  = "Tree Climber",
            "phone" = "8675309",
            "title" = "Nut Hider"
          },
          "OPERATIONS" = {
              "email" = "squirrel@squirrel.fake",
            "name"  = "Tree Climber",
            "phone" = "8675309",
            "title" = "Nut Hider"
          },
          "SECURITY" = {
              "email" = "squirrel@squirrel.fake",
            "name"  = "Tree Climber",
            "phone" = "8675309",
            "title" = "Nut Hider"
          }
        }
        "vpc_cidr" = ""
        ## This is short for sso user groups, log in as yourself into AWS console or AWS CLI call
        "sso_groups" = []
        ## This is for using SSO to access applications such as athena or redshift
        "sso_app_groups" = []
        ## Account status is set by the metadata json file or the OU location for closed. Defaults to open.
        "account_status" = dirname(acct) == "Root/4Closed" ? "closed" : "open"
        ## CICD environment for example (but not always): DEV, UAT, QA, PROD
        ## we're just default to PROD, please provide it in the account metadata, if you care
        "account_env" = "prod"
        ## This is name given to collection of accounts without environment postfix
        "account_group" = trimsuffix(jsondecode(file(format("%s/%s", local.structure_prefix, acct))).name, format("-%s", lookup(jsondecode(file(format("%s/%s", local.structure_prefix, acct))), "account_env", "prod")))
        ## this defaults to applicaton
        "account_type" = "application"
        ## this defaults to prod just for historical reason
        "account_subtype" = "prod"
        ## for historical purposes, these defaults to the name of account minus the environment suffix
        "application_name" = trimsuffix(jsondecode(file(format("%s/%s", local.structure_prefix, acct))).name, format("-%s", lookup(jsondecode(file(format("%s/%s", local.structure_prefix, acct))), "account_env", "prod")))
        "application_type" = trimsuffix(jsondecode(file(format("%s/%s", local.structure_prefix, acct))).name, format("-%s", lookup(jsondecode(file(format("%s/%s", local.structure_prefix, acct))), "account_env", "prod")))
      },
      ## This is the content of the account's metadata file in its entirety
      jsondecode(file(format("%s/%s", local.structure_prefix, acct))),
      {
        ## Inject bogus account number if someone hasn't applied the latest branch when a new account was created:
        "accountnum" = lookup(local.accountnum_mapping, jsondecode(file(format("%s/%s", local.structure_prefix, acct))).name, "000000000000")
      }
    )
    if(substr(strrev(basename(acct)), 0, length(local.account_file)) == strrev(local.account_file)) && (try((lookup(jsondecode(file(format("%s/%s", local.structure_prefix, acct))), "name", "none") != "none"), false))
  }
  ##this is a lookup for finding/verifying account name when all you have is account alias 
  ## You can do a data call for account alias via aws_iam_account_alias
  accounts = [for key in local.structure_files : trimprefix(key, join("", [local.structure_prefix, "/"])) if(substr(strrev(basename(key)), 0, length(local.account_file)) == strrev(local.account_file))]

  ##this is a lookup table where you provide alias and you get back name
  accounts_name = {
    for key, value in local.accounts_content :
    value.alias => value.name
  }

  ##this is a lookup table where you provide alias and you get back number
  accounts_number = {
    for key, value in local.accounts_content :
    value.alias => value.accountnum
  }

  ## just a list of numbers
  accounts_num_only = values(local.accounts_number)

  ##this is a lookup table where you provide number and get back name
  accounts_num_to_name = {
    for key, value in local.accounts_content :
    value.accountnum => value.name
  }

  ##this is a lookup table where you provide number and you get back alias and type 
  accounts_number_detail = {
    for key, value in local.accounts_content :
    value.accountnum => {
      name             = value.name,
      alias            = value.alias,
      account_group    = value.account_group,
      account_type     = value.account_type,
      account_subtype  = value.account_subtype,
      account_env      = value.account_env,
      application_name = value.application_name,
      application_type = value.application_type,
      vpc_name         = value.vpc_name,
      vpc_cidr         = value.vpc_cidr
    }
  }
  ##this is a lookup table where you provide alias and you get back number and type
  accounts_alias_detail = {
    for key, value in local.accounts_content :
    value.alias => {
      name             = value.name,
      account_number   = value.accountnum,
      account_group    = value.account_group,
      account_type     = value.account_type,
      account_subtype  = value.account_subtype,
      account_env      = value.account_env,
      application_name = value.application_name,
      application_type = value.application_type,
      vpc_name         = value.vpc_name,
      vpc_cidr         = value.vpc_cidr
    }
  }

  ##this is a lookup table where you provide alias and you get back account_type
  ##Remember, account_type is mandatory!
  accounts_type = {
    for key, value in local.accounts_content :
    value.alias => value.account_type
  }

  ##this is a lookup table for account_subtype, this may NOT exist for all accounts
  accounts_subtype = {
    for key, value in local.accounts_content :
    value.alias => value.account_subtype
  }

  ##Lookup table for account environment, this may not exist for all accounts
  accounts_env = {
    for key, value in local.accounts_content :
    value.alias => value.account_env
  }

  ##Lookup table for account status, this is either open or closed. Use this to toggle things on or off
  accounts_alias_to_status = {
    for key, value in local.accounts_content :
    value.alias => value.account_status
  }

  accounts_num_to_status = {
    for key, value in local.accounts_content :
    value.accountnum => value.account_status
  }

  ##Lookup table for application_name, this may not exist for all accounts
  application_name = {
    for key, value in local.accounts_content :
    value.alias => value.application_name
  }

  ##Lookup table for application_name, this may not exist for all accounts
  application_type = {
    for key, value in local.accounts_content :
    value.alias => value.application_type
  }

  ##Lookup table for account_group
  account_group = {
    for key, value in local.accounts_content :
    value.alias => value.account_group
  }

  ## Get list of all unique account_types
  unique_types = distinct([for key, value in local.accounts_type : value])

  ## Get list of all unique account_subtypes
  unique_subtypes = distinct([for key, value in local.accounts_subtype : value])

  ## Get list of all unique accounts_env
  unique_envs = distinct([for key, value in local.accounts_env : value])

  ## Get list of all unique application_name
  unique_app_names = distinct([for key, value in local.application_name : value])

  ## Get list of all unique application_type
  unique_app_types = distinct([for key, value in local.application_type : value])

  ## Get list of all unique account_group
  unique_account_group = distinct([for key, value in local.account_group : value])

  ## use the unique account type to create a map of account_type to accounts
  /* accounts_type_grouped = {
    for app in local.unique_types:
      app => [for key, value in local.accounts_type: key if value == app]
  }
 */
  accounts_type_grouped = {
    for type in local.unique_types :
    type => [for alias, thisType in local.accounts_type : alias if thisType == type]
  }

  accounts_subtype_grouped = {
    for subtype in local.unique_subtypes :
    subtype => [for alias, thisSubtype in local.accounts_subtype : alias if thisSubtype == subtype]
  }

  accounts_env_grouped = {
    for env in local.unique_envs :
    env => [for alias, thisEnv in local.accounts_env : alias if thisEnv == env]
  }

  accounts_app_name_grouped = {
    for app_name in local.unique_app_names :
    app_name => [for alias, thisAppName in local.application_name : alias if thisAppName == app_name]
  }

  accounts_app_type_grouped = {
    for app_type in local.unique_app_types :
    app_type => [for alias, thisAppType in local.application_type : alias if thisAppType == app_type]
  }

  accounts_groups_grouped = {
    for groupie in local.unique_account_group :
    groupie => [for alias, thisGroup in local.account_group : alias if thisGroup == groupie]
  }

  /*
  This ensures unique usage of environment per Account Group per Application Name, such as
  Account_group = {
    Application_Name = {
      DEV = blah
      PROD = blah 
      QA = blah
      UAT = blah
    }
  }
  */
  accounts_groups_to_app_name_to_env = {
    for groupie in local.unique_account_group :
    groupie => {
      for app_name in local.unique_app_names :
      app_name => {
        for my_alias in [for alias, details in local.accounts_alias_detail : alias if details.account_group == groupie && details.application_name == app_name] :
        lookup(local.accounts_env, my_alias) => my_alias
      }
      if length([for alias, details in local.accounts_alias_detail : alias if details.account_group == groupie && details.application_name == app_name]) > 0
    }
  }

  account_alternate_contacts = {
    for key, value in local.accounts_content :
    value.alias => value.alternate_contacts
  }

  ## Just get the email address of the contact, only email is unique all other may be different such as name or phone number
  account_alternate_contacts_email_billing    = distinct([for key, value in local.account_alternate_contacts : lower(lookup(lookup(value, "BILLING", {}), "email", "unknown"))])
  account_alternate_contacts_email_operations = distinct([for key, value in local.account_alternate_contacts : lower(lookup(lookup(value, "OPERATIONS", {}), "email", "unknown"))])
  account_alternate_contacts_email_security   = distinct([for key, value in local.account_alternate_contacts : lower(lookup(lookup(value, "SECURITY", {}), "email", "unknown"))])

  ## Take the unique email address and get the "first" name available
  account_alternate_contacts_billing = {
    for item in local.account_alternate_contacts_email_billing :
    item => [
      for key, value in local.account_alternate_contacts :
      lookup(lookup(value, "BILLING", {}), "name", "unknown")
      if lower(lookup(lookup(value, "BILLING", {}), "email", "unknown")) == item
    ][0]
  }
  account_alternate_contacts_operations = {
    for item in local.account_alternate_contacts_email_operations :
    item => [
      for key, value in local.account_alternate_contacts :
      lookup(lookup(value, "OPERATIONS", {}), "name", "unknown")
      if lower(lookup(lookup(value, "OPERATIONS", {}), "email", "unknown")) == item
    ][0]
  }
  account_alternate_contacts_security = {
    for item in local.account_alternate_contacts_email_security :
    item => [
      for key, value in local.account_alternate_contacts :
      lookup(lookup(value, "SECURITY", {}), "name", "unknown")
      if lower(lookup(lookup(value, "SECURITY", {}), "email", "unknown")) == item
    ][0]
  }

  ## nOw group all the groups under its contact
  account_alternate_contacts_billing_grouped = {
    for email, name in local.account_alternate_contacts_billing :
    "${name} (${email})" => [
      for key, value in local.account_alternate_contacts :
      key
      if lower(lookup(lookup(value, "BILLING", {}), "email", "unknown")) == email
    ]
  }
  account_alternate_contacts_operations_grouped = {
    for email, name in local.account_alternate_contacts_operations :
    "${name} (${email})" => [
      for key, value in local.account_alternate_contacts :
      key
      if lower(lookup(lookup(value, "OPERATIONS", {}), "email", "unknown")) == email
    ]
  }
  account_alternate_contacts_security_grouped = {
    for email, name in local.account_alternate_contacts_security :
    "${name} (${email})" => [
      for key, value in local.account_alternate_contacts :
      key
      if lower(lookup(lookup(value, "SECURITY", {}), "email", "unknown")) == email
    ]
  }

  ##this is a list of all places where ou files are found
  ous = [for key in local.structure_files : trimprefix(key, join("", [local.structure_prefix, "/"])) if basename(key) == local.ou_file]
  ##this is a list of all places where policy files are found
  policies = [for key in local.structure_files : trimprefix(key, join("", [local.structure_prefix, "/"])) if(substr(strrev(basename(key)), 0, length(local.policy_file)) == strrev(local.policy_file))]

  ##this is a lookup table where you provide alias and you get back vpc_cidr
  accounts_vpc_cidr = {
    for key, value in local.accounts_content :
    value.alias => value.vpc_cidr
  }

  ## Get list of all VPC Cidrs
  all_vpc_cidrs    = compact([for key, value in local.accounts_vpc_cidr : value])
  unique_vpc_cidrs = distinct(local.all_vpc_cidrs)


  accounts_aws_sso = {
    for key, value in local.accounts_content :
    value.accountnum => value.sso_groups
  }

  ##get all the permissions sets as they are defined in the files
  sso_permission_sets_details = {
    for filename in local.permset_files :
    lookup(jsondecode(file(format("%s/%s", local.permset_prefix, filename))), "name", "") => jsondecode(file(format("%s/%s", local.permset_prefix, filename)))
    if lookup(jsondecode(file(format("%s/%s", local.permset_prefix, filename))), "name", "") != ""
  }
  /*
  {
    "ViewOnlyAccess" = {
        "description" = "Lowest access into our accounts. Uses managed policy ViewOnlyAccess.",
        "inline_policy"= {},
        "managed_policy_arns" = [
          "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
        ],
        "name" = "ViewOnlyAccess",
        "session_duration" = "PT1H"
    }
  }
  */

  ##just extract the names of permission sets
  sso_permission_set_names = [for key, value in local.sso_permission_sets_details : key]
  ##Extract the policyArn from the permission sets (this is up to 10 per permset)
  sso_permset_poli_list = { for item in flatten([for key, value in local.sso_permission_sets_details : [for child in value.managed_policy_arns : { "permset" = key, "policyarn" = child }]]) : join("_", [item.permset, replace(item.policyarn, "arn:aws:iam::aws:", "")]) => item }
  /*
  {
    ViewOnlyAccess_policy/job-function/ViewOnlyAccess = {
      permset   = "ViewOnlyAccess"
      policyarn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
    }
  }
  */

  ##Extract the inline policies from the permission sets (this is just 1)
  ## Need to jsonencode the policy so that it can be used as-is 
  sso_permset_line_list = {
    for key, value in local.sso_permission_sets_details :
    key => jsonencode(value["inline_policy"])
    if length(value["inline_policy"]) > 0
  }
  ##this moves the key account into the map with the group and permission_sets
  ## this also verifies that there are keys group and permission_sets
  sso_flatten = flatten([for thinga, thingb in { for key, value in local.accounts_aws_sso : key => [for item in value : merge(item, { "account" = key }) if((lookup(item, "group", false) != false) && (lookup(item, "permission_sets", false) != false))] } : thingb])
  ##this removes any undefined permission_sets from the sso_flatten above, if it's not there, don't try to use it
  ##this is a nice view if you want to see which account has which groups
  sso_flatten_permset_verify = [for item in local.sso_flatten : merge(item, { "permission_sets" = setintersection(item.permission_sets, local.sso_permission_set_names) }) if length(setintersection(item.permission_sets, local.sso_permission_set_names)) > 0]
  /*
  [
  + {
      + account         = "111111111111"
      + group           = "XXX-readonly"
      + permission_sets = [
          + "ViewOnlyAccess",
          + "ViewOnlyAccess2",
        ]
    },
  + {
      + account         = "222222222222"
      + group           = "XXX-readonly"
      + permission_sets = [
          + "ViewOnlyAccess",
        ]
    },
  ]
  */

  ##this ultimate flattend collection of account, group, and permission_set into individual items in a list
  ##this makes it easy to pass into resource to create this matching
  sso_pancake_batch = flatten([for item in local.sso_permission_set_names : [for flat in local.sso_flatten_permset_verify : merge(flat, { "permission_sets" = item }) if contains(flat.permission_sets, item)]])
  /*
  [
      {
          account         = "111111111111"
          group           = "xxx-readonly"
          permission_sets = "ViewOnlyAccess"
      },
      {
          account         = "111111111111"
          group           = "xxx-readonly"
          permission_sets = "ViewOnlyAccess"
      }
  ]
  */

  ##this gets all the unique groups being used
  sso_groups_unique = distinct([for item in local.sso_flatten_permset_verify : item.group])
  ##this creates group based on sso_group
  ##this is a good way to view how each group is used
  sso_groups_based = { for item in local.sso_groups_unique : item => [for stuff in local.sso_flatten_permset_verify : stuff if stuff.group == item] }
  /*
  {
    "AWS-ReadOnly" [
      {
        "account" "111111111111",
        "group" "xxx-readonly",
        "permission_sets" [
            "ViewOnlyAccess"
        ]
      },
      {
        "account" "222222222222",
        "group" "xxx-readonly",
        "permission_sets" [
            "ViewOnlyAccess"
        ]
      }
    ]
  }
  */

  /*
  accounts_aws_sso_app is being built out the same way it was being used when this
  was in policies workspace. That is the reason for why it looks the way it looks

  the SSOGroupList can take in a list of groups but in our implementation, it is 1 to 1 from sso_app and role
  clusterArn and dbGroupList are only for RedShift
  */
  accounts_aws_sso_app = {
    for key, value in local.accounts_content :
    value.accountnum => [
      for item in value.sso_app_groups :
      {
        name              = item.name
        targetService     = item.targetService.name
        clusterArn        = lookup(item.targetService, "clusterArn", "")
        dbGroupList       = lookup(item.targetService, "dbGroupList", [])
        displayName       = lookup(item, "displayName", format("%s-%s", item.name, "saml-app")),
        description       = lookup(item, "description", format("%s-%s", item.name, "saml-app")),
        accountNumber     = value.accountnum,
        iam_role          = format("arn:aws:iam::%s:role/%s", value.accountnum, lookup(item, "iam_role_name", format("%s-%s", item.name, "saml-role"))),
        iam_saml_provider = format("arn:aws:iam::%s:saml-provider/%s", value.accountnum, lookup(item, "iam_saml_provider_name", format("%s-%s", item.name, "idp-federation"))),
        SSOGroupsList     = [lookup(item, "group", format("%s-%s", "AWS", item.name))]
      }
    ]
    if length(value.sso_app_groups) > 0
  }

  accounts_aws_sso_app_groups = distinct(flatten([for key, value in local.accounts_aws_sso_app : [for item in value : item.SSOGroupsList]]))
}


