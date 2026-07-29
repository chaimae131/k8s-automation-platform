terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

locals {
  master_name = "k8s-master"
  workers     = ["k8s-worker1", "k8s-worker2"]
  generated   = "${path.module}/generated"
}

#---------------------------------------
# CREATE MASTER VM
#---------------------------------------
resource "null_resource" "master" {
  provisioner "local-exec" {
    command = <<-EOC
      echo ">>> Creating Kubernetes Master VM..."
      mkdir -p ${var.vm_dir}/${local.master_name}
      vmrun clone "${var.base_vm_path}/UbuntuServer.vmx" "${var.vm_dir}/${local.master_name}/${local.master_name}.vmx" full
      
      sed -i 's/displayName = .*/displayName = "master"/' "${var.vm_dir}/${local.master_name}/${local.master_name}.vmx"

      # Force VMware to regenerate MAC and UUID
      sed -i 's/ethernet0.addressType.*/ethernet0.addressType = "generated"/' "${var.vm_dir}/${local.master_name}/${local.master_name}.vmx"
      sed -i '/^uuid.action/d' "${var.vm_dir}/${local.master_name}/${local.master_name}.vmx"
      echo 'uuid.action = "create"' >> "${var.vm_dir}/${local.master_name}/${local.master_name}.vmx"

      vmrun start "${var.vm_dir}/${local.master_name}/${local.master_name}.vmx"
      
      echo ">>> Waiting for Master VM to boot and obtain new IP (this may take 60-90 seconds)..."
      sleep 90
    EOC
  }
}

#---------------------------------------
# CREATE WORKER 1 (Sequential - must complete before Worker 2)
#---------------------------------------
resource "null_resource" "worker1" {
  provisioner "local-exec" {
    command = <<-EOC
      echo ">>> Creating Worker VM k8s-worker1..."
      mkdir -p ${var.vm_dir}/k8s-worker1
      vmrun clone "${var.base_vm_path}/UbuntuServer.vmx" "${var.vm_dir}/k8s-worker1/k8s-worker1.vmx" full
      
      sed -i "s/displayName = .*/displayName = \"worker1\"/" "${var.vm_dir}/k8s-worker1/k8s-worker1.vmx"

      # Force VMware to regenerate MAC and UUID
      sed -i 's/ethernet0.addressType.*/ethernet0.addressType = "generated"/' "${var.vm_dir}/k8s-worker1/k8s-worker1.vmx"
      sed -i '/^uuid.action/d' "${var.vm_dir}/k8s-worker1/k8s-worker1.vmx"
      echo 'uuid.action = "create"' >> "${var.vm_dir}/k8s-worker1/k8s-worker1.vmx"

      vmrun start "${var.vm_dir}/k8s-worker1/k8s-worker1.vmx"
      
      echo ">>> Waiting for Worker 1 to boot and obtain new IP (this may take 60-90 seconds)..."
      sleep 90
    EOC
  }

  depends_on = [null_resource.master]
}

#---------------------------------------
# CREATE WORKER 2 (Sequential - starts after Worker 1 completes)
#---------------------------------------
resource "null_resource" "worker2" {
  provisioner "local-exec" {
    command = <<-EOC
      echo ">>> Creating Worker VM k8s-worker2..."
      mkdir -p ${var.vm_dir}/k8s-worker2
      vmrun clone "${var.base_vm_path}/UbuntuServer.vmx" "${var.vm_dir}/k8s-worker2/k8s-worker2.vmx" full
      
      sed -i "s/displayName = .*/displayName = \"worker2\"/" "${var.vm_dir}/k8s-worker2/k8s-worker2.vmx"

      # Force VMware to regenerate MAC and UUID
      sed -i 's/ethernet0.addressType.*/ethernet0.addressType = "generated"/' "${var.vm_dir}/k8s-worker2/k8s-worker2.vmx"
      sed -i '/^uuid.action/d' "${var.vm_dir}/k8s-worker2/k8s-worker2.vmx"
      echo 'uuid.action = "create"' >> "${var.vm_dir}/k8s-worker2/k8s-worker2.vmx"

      vmrun start "${var.vm_dir}/k8s-worker2/k8s-worker2.vmx"
      
      echo ">>> Waiting for Worker 2 to boot and obtain new IP (this may take 60-90 seconds)..."
      sleep 90
    EOC
  }

  depends_on = [null_resource.worker1]
}

#---------------------------------------
# GET MASTER IP (with retry logic)
#---------------------------------------
resource "null_resource" "get_master_ip" {
  provisioner "local-exec" {
    command = <<-EOC
      echo ">>> Fetching Master VM IP..."
      mkdir -p ${local.generated}
      
      # Retry logic to ensure IP is obtained
      max_attempts=20
      attempt=0
      while [ $attempt -lt $max_attempts ]; do
        if vmrun getGuestIPAddress "${var.vm_dir}/${local.master_name}/${local.master_name}.vmx" -wait > ${local.generated}/master_ip.txt 2>/dev/null; then
          ip=$(cat ${local.generated}/master_ip.txt | tr -d '\n\r ')
          if [ ! -z "$ip" ] && [ "$ip" != "unknown" ]; then
            echo ">>> Master IP obtained: $ip"
            exit 0
          fi
        fi
        echo ">>> Attempt $((attempt + 1))/$max_attempts - Waiting for IP..."
        sleep 5
        attempt=$((attempt + 1))
      done
      
      echo ">>> ERROR: Failed to obtain Master IP after $max_attempts attempts"
      exit 1
    EOC
  }

  depends_on = [null_resource.master]
}

#---------------------------------------
# GET WORKER 1 IP (with retry logic)
#---------------------------------------
resource "null_resource" "get_worker1_ip" {
  provisioner "local-exec" {
    command = <<-EOC
      echo ">>> Fetching Worker 1 IP..."
      mkdir -p ${local.generated}
      
      # Retry logic to ensure IP is obtained
      max_attempts=20
      attempt=0
      while [ $attempt -lt $max_attempts ]; do
        if vmrun getGuestIPAddress "${var.vm_dir}/k8s-worker1/k8s-worker1.vmx" -wait > ${local.generated}/worker1_ip.txt 2>/dev/null; then
          ip=$(cat ${local.generated}/worker1_ip.txt | tr -d '\n\r ')
          if [ ! -z "$ip" ] && [ "$ip" != "unknown" ]; then
            echo ">>> Worker 1 IP obtained: $ip"
            exit 0
          fi
        fi
        echo ">>> Attempt $((attempt + 1))/$max_attempts - Waiting for IP..."
        sleep 5
        attempt=$((attempt + 1))
      done
      
      echo ">>> ERROR: Failed to obtain Worker 1 IP after $max_attempts attempts"
      exit 1
    EOC
  }

  depends_on = [null_resource.worker1]
}

#---------------------------------------
# GET WORKER 2 IP (with retry logic)
#---------------------------------------
resource "null_resource" "get_worker2_ip" {
  provisioner "local-exec" {
    command = <<-EOC
      echo ">>> Fetching Worker 2 IP..."
      mkdir -p ${local.generated}
      
      # Retry logic to ensure IP is obtained
      max_attempts=20
      attempt=0
      while [ $attempt -lt $max_attempts ]; do
        if vmrun getGuestIPAddress "${var.vm_dir}/k8s-worker2/k8s-worker2.vmx" -wait > ${local.generated}/worker2_ip.txt 2>/dev/null; then
          ip=$(cat ${local.generated}/worker2_ip.txt | tr -d '\n\r ')
          if [ ! -z "$ip" ] && [ "$ip" != "unknown" ]; then
            echo ">>> Worker 2 IP obtained: $ip"
            exit 0
          fi
        fi
        echo ">>> Attempt $((attempt + 1))/$max_attempts - Waiting for IP..."
        sleep 5
        attempt=$((attempt + 1))
      done
      
      echo ">>> ERROR: Failed to obtain Worker 2 IP after $max_attempts attempts"
      exit 1
    EOC
  }

  depends_on = [null_resource.worker2]
}

#---------------------------------------
# READ IP FILES
#---------------------------------------
data "local_file" "master_ip" {
  filename   = "${local.generated}/master_ip.txt"
  depends_on = [null_resource.get_master_ip]
}

data "local_file" "worker1_ip" {
  filename   = "${local.generated}/worker1_ip.txt"
  depends_on = [null_resource.get_worker1_ip]
}

data "local_file" "worker2_ip" {
  filename   = "${local.generated}/worker2_ip.txt"
  depends_on = [null_resource.get_worker2_ip]
}

#---------------------------------------
# COPY SSH KEYS TO ALL VMS
#---------------------------------------
resource "null_resource" "copy_ssh_key_master" {
  provisioner "local-exec" {
    command = <<-EOC
      echo ">>> Copying SSH key to Master VM..."
      
      # Read the public key
      SSH_PUB_KEY=$(cat ~/.ssh/k8s_ansible_key.pub)
      
      # Wait a bit to ensure VM is fully ready
      sleep 10
      
      # Create .ssh directory on master
      vmrun -gu k8s -gp kali runScriptInGuest "${var.vm_dir}/${local.master_name}/${local.master_name}.vmx" /bin/bash "mkdir -p /home/k8s/.ssh && chmod 700 /home/k8s/.ssh"
      
      # Copy public key to authorized_keys
      vmrun -gu k8s -gp kali runScriptInGuest "${var.vm_dir}/${local.master_name}/${local.master_name}.vmx" /bin/bash "echo '$SSH_PUB_KEY' >> /home/k8s/.ssh/authorized_keys && chmod 600 /home/k8s/.ssh/authorized_keys && chown -R k8s:k8s /home/k8s/.ssh"
      
      echo ">>> SSH key copied to Master successfully"
    EOC
  }

  depends_on = [null_resource.get_master_ip]
}

resource "null_resource" "copy_ssh_key_worker1" {
  provisioner "local-exec" {
    command = <<-EOC
      echo ">>> Copying SSH key to Worker 1..."
      
      SSH_PUB_KEY=$(cat ~/.ssh/k8s_ansible_key.pub)
      
      sleep 10
      
      vmrun -gu k8s -gp kali runScriptInGuest "${var.vm_dir}/k8s-worker1/k8s-worker1.vmx" /bin/bash "mkdir -p /home/k8s/.ssh && chmod 700 /home/k8s/.ssh"
      
      vmrun -gu k8s -gp kali runScriptInGuest "${var.vm_dir}/k8s-worker1/k8s-worker1.vmx" /bin/bash "echo '$SSH_PUB_KEY' >> /home/k8s/.ssh/authorized_keys && chmod 600 /home/k8s/.ssh/authorized_keys && chown -R k8s:k8s /home/k8s/.ssh"
      
      echo ">>> SSH key copied to Worker 1 successfully"
    EOC
  }

  depends_on = [null_resource.get_worker1_ip]
}

resource "null_resource" "copy_ssh_key_worker2" {
  provisioner "local-exec" {
    command = <<-EOC
      echo ">>> Copying SSH key to Worker 2..."
      
      SSH_PUB_KEY=$(cat ~/.ssh/k8s_ansible_key.pub)
      
      sleep 10
      
      vmrun -gu k8s -gp kali runScriptInGuest "${var.vm_dir}/k8s-worker2/k8s-worker2.vmx" /bin/bash "mkdir -p /home/k8s/.ssh && chmod 700 /home/k8s/.ssh"
      
      vmrun -gu k8s -gp kali runScriptInGuest "${var.vm_dir}/k8s-worker2/k8s-worker2.vmx" /bin/bash "echo '$SSH_PUB_KEY' >> /home/k8s/.ssh/authorized_keys && chmod 600 /home/k8s/.ssh/authorized_keys && chown -R k8s:k8s /home/k8s/.ssh"
      
      echo ">>> SSH key copied to Worker 2 successfully"
    EOC
  }

  depends_on = [null_resource.get_worker2_ip]
}

#---------------------------------------
# CONFIGURE PASSWORDLESS SUDO ON ALL VMS
#---------------------------------------
resource "null_resource" "setup_sudo_master" {
  provisioner "local-exec" {
    command = <<-EOC
      echo ">>> Configuring passwordless sudo on Master..."
      vmrun -gu k8s -gp kali runScriptInGuest "${var.vm_dir}/${local.master_name}/${local.master_name}.vmx" /bin/bash "echo 'kali' | sudo -S sh -c 'echo \"k8s ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/k8s && chmod 440 /etc/sudoers.d/k8s'"
      echo ">>> Passwordless sudo configured on Master"
    EOC
  }

  depends_on = [null_resource.copy_ssh_key_master]
}

resource "null_resource" "setup_sudo_worker1" {
  provisioner "local-exec" {
    command = <<-EOC
      echo ">>> Configuring passwordless sudo on Worker 1..."
      vmrun -gu k8s -gp kali runScriptInGuest "${var.vm_dir}/k8s-worker1/k8s-worker1.vmx" /bin/bash "echo 'kali' | sudo -S sh -c 'echo \"k8s ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/k8s && chmod 440 /etc/sudoers.d/k8s'"
      echo ">>> Passwordless sudo configured on Worker 1"
    EOC
  }

  depends_on = [null_resource.copy_ssh_key_worker1]
}

resource "null_resource" "setup_sudo_worker2" {
  provisioner "local-exec" {
    command = <<-EOC
      echo ">>> Configuring passwordless sudo on Worker 2..."
      vmrun -gu k8s -gp kali runScriptInGuest "${var.vm_dir}/k8s-worker2/k8s-worker2.vmx" /bin/bash "echo 'kali' | sudo -S sh -c 'echo \"k8s ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/k8s && chmod 440 /etc/sudoers.d/k8s'"
      echo ">>> Passwordless sudo configured on Worker 2"
    EOC
  }

  depends_on = [null_resource.copy_ssh_key_worker2]
}

#---------------------------------------
# VERIFY SSH ACCESS
#---------------------------------------
resource "null_resource" "verify_ssh_access" {
  provisioner "local-exec" {
    command = <<-EOC
      echo ">>> Verifying SSH access to all nodes..."
      
      # Wait a moment for SSH service to be ready
      sleep 5
      
      echo ">>> Testing Master SSH connection..."
      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -i ~/.ssh/k8s_ansible_key k8s@${trimspace(data.local_file.master_ip.content)} "echo 'Master SSH connection successful'"
      
      echo ">>> Testing Worker 1 SSH connection..."
      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -i ~/.ssh/k8s_ansible_key k8s@${trimspace(data.local_file.worker1_ip.content)} "echo 'Worker 1 SSH connection successful'"
      
      echo ">>> Testing Worker 2 SSH connection..."
      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -i ~/.ssh/k8s_ansible_key k8s@${trimspace(data.local_file.worker2_ip.content)} "echo 'Worker 2 SSH connection successful'"
      
      echo ">>> All SSH connections verified successfully!"
    EOC
  }

  depends_on = [
    null_resource.setup_sudo_master,
    null_resource.setup_sudo_worker1,
    null_resource.setup_sudo_worker2
  ]
}

#---------------------------------------
# GENERATE ANSIBLE INVENTORY
#---------------------------------------
locals {
  inventory_content = templatefile(
    "${path.module}/templates/inventory.tpl",
    {
      master_ip  = trimspace(data.local_file.master_ip.content)
      worker_ips = [
        trimspace(data.local_file.worker1_ip.content),
        trimspace(data.local_file.worker2_ip.content)
      ]
    }
  )
}

resource "local_file" "inventory" {
  content  = local.inventory_content
  filename = "${path.module}/../ansible/inventory.ini"
  depends_on = [
    null_resource.verify_ssh_access
  ]
}
