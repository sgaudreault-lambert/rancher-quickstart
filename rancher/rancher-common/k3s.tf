# K3s cluster for Rancher

resource "ssh_resource" "install_k3s" {
  # Use your public IP input variable for the host connection
  host = var.node_public_ip
  commands = [
    "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC=\"server --node-external-ip ${var.node_public_ip} --node-ip ${var.node_internal_ip} --tls-san ${var.node_public_ip}\" INSTALL_K3S_VERSION=${var.rancher_kubernetes_version} sh -"
  ]
  user        = var.node_username
  private_key = var.ssh_private_key_pem
}

resource "ssh_resource" "wait_for_k3s" {
  depends_on = [
    ssh_resource.install_k3s
  ]

  triggers = {
    k3s_version = var.rancher_kubernetes_version
  }

  host = var.node_public_ip
  commands = [
    "bash -c 'for i in $(seq 1 60); do if sudo systemctl is-active --quiet k3s && curl -sk https://${var.node_public_ip}:6443/healthz >/dev/null 2>&1; then exit 0; fi; sleep 10; done; echo \"k3s API did not become ready in time\" >&2; exit 1'"
  ]
  user        = var.node_username
  private_key = var.ssh_private_key_pem
}

resource "ssh_resource" "retrieve_config" {
  depends_on = [
    ssh_resource.wait_for_k3s
  ]

  triggers = {
    k3s_version = var.rancher_kubernetes_version
  }

  host = var.node_public_ip
  commands = [
    "sudo sed \"s/127.0.0.1/${var.node_public_ip}/g\" /etc/rancher/k3s/k3s.yaml"
  ]
  user        = var.node_username
  private_key = var.ssh_private_key_pem
}
