# terraform-json-database
An example of defining database using json files in Terraform. Specifically, this workspace defines the structure of AWS Organization in a folder structure. 

This can be used to pull following information about your Org:

- Placement of OU Policies (both SCP and TAG)
- OU Placements in the structure
- Account Placement in the strucuture within OU (if ou.txt file is not created properly, then the account/OU will go under Root)
- Account Alias to Account Name lookup. If you got Account alias, you can lookup what the Name is. Typically the alias is just "stifel-ACCOUNTNAME"
- Account Attributes

## Updating the Structure

### OU

Create a file names `ou.txt` into the folder that you want to be treated as OU in the ORG

### Account Information (minus ID)

Create some unique file name that ends extension `.acct.json` into a folder and the first folder that has a file `ou.txt` will be treated as the parent OU for this account.
At minimum, there must be following in the file. Additional instruction can be found in the baseline solution module.

````json
{
    "name": "cool-account"
}
````

### Account ID

Since account ID can't be known until the account is created, this is kept separately and created automatically when a new account is created. This will be merged into account content. If you need to manually update account id to account name relationship, you must also edit this file. There is no trigger to update this after an account has been created. See a folder `accounts` and find the filename that is the account ID. Inside the file should have two pieces of information. Accountalias is not used here and can be ignored, if present.

```json
{
    "accountname":  "cool-account",
    "accountnum":  "111111111111"
}

```

### Policy

Create a policy file that ends in extension `pol.json` into a folder to deploy a policy to that folder. If `ou.txt` is missing then this policy will be applied to Root. The full name of the policy must match the policy name found in the org policy solution module.

## Getting the Metadata

### TFE Workspace Call
````
data "terraform_remote_state" "remote_state" {
  backend = "remote"

  config = {
    organization = "my_default"
    workspaces = {
      name = " my_database_workspace"
    }
  }
}
````