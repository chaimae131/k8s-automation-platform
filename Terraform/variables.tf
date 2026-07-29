variable "base_vm_path" {
  description = "Path to base Ubuntu VMX file (template)"
  type        = string
  default     = "/home/hasnae/vmware/UbuntuServer"
}

variable "vm_dir" {
  description = "Directory where cloned VMs will be stored"
  type        = string
  default     = "/home/hasnae/k8s/vms"
}

variable "username" {
  description = "VM guest username"
  type        = string
  default     = "k8s"
}

variable "password" {
  description = "VM guest password"
  type        = string
  default     = "kali"
}

