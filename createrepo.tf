terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "4.17.0"
    }
  }
}

provider "github" {
   
      token = "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"
}

resource "github_repository" "Terraform" {
  name        = "Nas_Terraform"
  description = "all Terraform demo files"

  visibility = "public"

  delete_branch_on_merge = true
}