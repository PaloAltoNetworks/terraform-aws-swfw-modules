variable "global_tags" {
  description = "Map of arbitrary tags to apply to all resources."
  default     = {}
  type        = map(any)
}

variable "prefix" {
  description = "The prefix to use for bucket name, IAM role name, and IAM role policy name. It is allowed to use dash \"-\" as the last character."
  default     = "bootstrap-"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "Name of the instance profile to create. If empty, name will be auto-generated."
  default     = ""
  type        = string
}

variable "create_iam_role_policy" {
  description = "If true, a new IAM role with policy will be created. When false, name of existing IAM role to use has to be provided in `iam_role_name` variable."
  default     = true
  type        = bool
}

variable "iam_role_name" {
  description = "Name of a IAM role to reuse or create (depending on `create_iam_role_policy` value)."
  default     = null
  type        = string
}

variable "force_destroy" {
  description = "Set to false to prevent Terraform from destroying a bucket with unknown objects or locked objects."
  default     = true
  type        = bool
}

variable "source_root_directory" {
  description = "The source directory to become the bucket's root directory. If empty uses `files` subdirectory of a Terraform configuration root directory."
  default     = ""
  type        = string
}

variable "bootstrap_directories" {
  description = "List of subdirectories to be created inside the bucket (whether or not they exist locally inside the `source_root_directory`). A hardcoded pan-os requirement."
  default = [
    "config/",
    "content/",
    "software/",
    "license/",
    "plugins/"
  ]
  type = list(string)
}

variable "bootstrap_options" {
  description = <<-EOF
  Object define bootstrap options used in the init-cfg.txt file.

  There are available bootstrap parameters:
  - `hostname`                    - (`string`, optional) The hostname of the VM-series instance.
  - `mgmt-interface-swap`         - (`string`, optional) Allows to swap the management interface with the dataplane interface eth1/1.
  - `panorama-server`             - (`string`, optional) The FQDN or IP address of the primary Panorama server.
  - `panorama-server-2`           - (`string`, optional) The FQDN or IP address of the secondary Panorama server.
  - `tplname`                     - (`string`, optional) The Panorama template stack name.
  - `dgname`                      - (`string`, optional) The Panorama device group name.
  - `cgname`                      - (`string`, optional) The Panorama collector group name.
  - `dns-primary`                 - (`string`, optional) The IP address of the primary DNS server.
  - `dns-secondary`               - (`string`, optional) The IP address of the secondary DNS server.
  - `auth-key`                    - (`string`, optional) VM-Series authentication key generated via plugin sw_fw_license.
  - `vm-auth-key`                 - (`string`, optional) VM-Series authentication key generated on Panorama.
  - `op-command-modes`            - (`string`, optional) Set jumbo-frame and/or mgmt-interface-swap.
  - `plugin-op-commands`          - (`string`, optional) Set plugin-op-commands.
  - `dhcp-send-hostname`          - (`string`, optional) The DHCP server determines a value of yes or no. If yes, the firewall sends its hostname to the DHCP server.
  - `dhcp-send-client-id`         - (`string`, optional) The DHCP server determines a value of yes or no. If yes, the firewall sends its client ID to the DHCP server.
  - `dhcp-accept-server-hostname` - (`string`, optional) The DHCP server determines a value of yes or no. If yes, the firewall accepts its hostname from the DHCP server.
  - `dhcp-accept-server-domain`   - (`string`, optional) The DHCP server determines a value of yes or no. If yes, the firewall accepts its DNS server from the DHCP server.
  - `vm-series-auto-registration-pin-id` - (`string`, optional) The VM-Series registration PIN ID for installing the device certificate on the VM-Series firewall.
  - `vm-series-auto-registration-pin-value` - (`string`, optional) The VM-Series registration PIN Value for installing the device certificate on the VM-Series firewall.
  EOF

  type = object({
    hostname                              = optional(string)
    mgmt-interface-swap                   = optional(string)
    panorama-server                       = optional(string)
    panorama-server-2                     = optional(string)
    tplname                               = optional(string)
    dgname                                = optional(string)
    cgname                                = optional(string)
    dns-primary                           = optional(string)
    dns-secondary                         = optional(string)
    auth-key                              = optional(string)
    vm-auth-key                           = optional(string)
    op-command-modes                      = optional(string)
    plugin-op-commands                    = optional(string)
    dhcp-send-hostname                    = optional(string)
    dhcp-send-client-id                   = optional(string)
    dhcp-accept-server-hostname           = optional(string)
    dhcp-accept-server-domain             = optional(string)
    vm-series-auto-registration-pin-id    = optional(string)
    vm-series-auto-registration-pin-value = optional(string)
  })
}

variable "create_bucket" {
  description = "If true, a new bucket will be created. When false, name of existing bucket to use has to be provided in `bucket_name` variable."
  default     = true
  type        = bool
}

variable "bucket_name" {
  description = "Name of a bucket to reuse or create (depending on `create_bucket` value). In the latter case - if empty, the name will be auto-generated."
  default     = ""
  type        = string
}
