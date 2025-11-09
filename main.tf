terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
  }
}

variable "dotfiles" {
  type    = list(string)
  default = [".profile", ".profile-alias", ".profile-env", ".profile-function"]
}

resource "null_resource" "dotfiles-install" {
  for_each = toset(var.dotfiles)
  provisioner "local-exec" {
    command = "cp conf/${each.key} $${HOME}/${each.key}"
  }
}

resource "null_resource" "global-ignore-install" {
  triggers = {
    gitignore = filemd5("conf/.gitignore_global")
  }
  provisioner "local-exec" {
    command = "cp conf/.gitignore_global $${HOME}/.gitignore_global"
  }
  provisioner "local-exec" {
    command = "git config --global core.excludesfile $${HOME}/.gitignore_global"
  }
}

resource "null_resource" "brew-cask-install" {
  triggers = {
    casks = filemd5("casks.txt")
  }
  provisioner "local-exec" {
    command = "while read -r cask; do [[ -n \"$cask\" ]] && (brew list --cask \"$cask\" &>/dev/null || brew install --cask \"$cask\"); done < casks.txt"
  }
}

resource "null_resource" "brew-formulae-install" {
  triggers = {
    formulae = filemd5("formulae.txt")
  }
  provisioner "local-exec" {
    command = "while read -r formulae; do [[ -n \"$formulae\" ]] && (brew list \"$formulae\" &>/dev/null || brew install \"$formulae\"); done < formulae.txt"
  }
}

resource "null_resource" "terminal-updates" {
  provisioner "local-exec" {
    command = "rm -rf $${HOME}/.oh-my-zsh"
  }

  provisioner "local-exec" {
    command = "sh -c \"$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" 2>/dev/null"
  }

  provisioner "local-exec" {
    command = "echo \"source $${HOME}/.profile\" >> $${HOME}/.zshrc"
  }
}

resource "null_resource" "docker-updates" {
  provisioner "local-exec" {
    command = "mkdir -p $${HOME}/.docker/cli-plugins && ln -sfn /usr/local/opt/docker-compose/bin/docker-compose $${HOME}/.docker/cli-plugins/docker-compose"
  }
  depends_on = [
    null_resource.brew-formulae-install
  ]
}

