# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

# Full configuration options can be found at https://developer.hashicorp.com/vault/docs/configuration

ui = true
api_addr = "http://0.0.0.0:9412"

mlock = true
disable_mlock = false

storage "file" {
  path = "/opt/vault/data"
}

listener "unix" {
  address = "/opt/vault/vault.sock"
}

listener "tcp" {
  address = "0.0.0.0:9412"
  tls_disable = 1
}