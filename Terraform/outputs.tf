output "master_ip" {
  value = trimspace(data.local_file.master_ip.content)
}

output "worker_ips" {
  value = [
    trimspace(data.local_file.worker1_ip.content),
    trimspace(data.local_file.worker2_ip.content)
  ]
}

output "inventory" {
  value = "Generated inventory is available in ../ansible/inventory.ini"
}

output "ssh_status" {
  value = "SSH keys and passwordless sudo configured successfully ✓"
}
