variable "region" {
  default = "West Europe"
}

variable "ssh_public_key" {
}

variable "ssh_private_key" {
}

variable "subscription_id" {
}

variable "client_id" {
}

variable "tenant_id" {
}

variable "app_environment" {
  default = "Development"
}

provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.21.0"
  
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  tenant_id       = "${var.tenant_id}"
}

terraform {
  backend "azurerm" {
    storage_account_name = "youraccount"
    container_name       = "yourcontainer"
    key                  = "terraform.tfstate"
  }
}
  
resource "azurerm_resource_group" "app" {
  name     = "terraformtutorial_${terraform.workspace}"
  location = "${var.region}"
}

resource "azurerm_storage_account" "hdfs" {
  name                     = "terraformtutorial${terraform.workspace}"
  resource_group_name      = "${azurerm_resource_group.app.name}"
  location                 = "${azurerm_resource_group.app.location}"
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
}

resource "azurerm_virtual_network" "app" {
  name                = "terraformtutorial-network-${terraform.workspace}"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.app.location}"
  resource_group_name = "${azurerm_resource_group.app.name}"
}

resource "azurerm_subnet" "app" {
  name                 = "terraformtutorial-subnet-${terraform.workspace}"
  resource_group_name  = "${azurerm_resource_group.app.name}"
  virtual_network_name = "${azurerm_virtual_network.app.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "app" {
  name                = "terraformtutorial-public-ip-${terraform.workspace}"
  location            = "${azurerm_resource_group.app.location}"
  resource_group_name = "${azurerm_resource_group.app.name}"
  allocation_method   = "Static"
  domain_name_label   = "terraformtutorial-${terraform.workspace}"
}

resource "azurerm_network_interface" "app" {
  name                = "terraformtutorial-nic-${terraform.workspace}"
  location            = "${azurerm_resource_group.app.location}"
  resource_group_name = "${azurerm_resource_group.app.name}"

  ip_configuration {
    name                          = "terraformtutorial-ipconfiguration-${terraform.workspace}"
    subnet_id                     = "${azurerm_subnet.app.id}"
    private_ip_address_allocation = "Dynamic"
	public_ip_address_id          = "${azurerm_public_ip.app.id}"
  }
}

resource "azurerm_virtual_machine" "app" {
  name                  = "terraformtutorial-vm-${terraform.workspace}"
  location              = "${azurerm_resource_group.app.location}"
  resource_group_name   = "${azurerm_resource_group.app.name}"
  network_interface_ids = ["${azurerm_network_interface.app.id}"]
  vm_size               = "Standard_B2s"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "terraformtutorial-vm-disk-${terraform.workspace}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "superadmin"
  }
  os_profile_linux_config {
    disable_password_authentication = true
	ssh_keys {
            path     = "/home/superadmin/.ssh/authorized_keys"
            key_data = "${var.ssh_public_key}"
        }
  }
  
  provisioner "file" {
    source      = "../Scripts/provisionVM.sh"
    destination = "/tmp/provisionVM.sh"
	
	connection {
		type     = "ssh"
		user     = "superadmin"
		private_key = "${var.ssh_private_key}"
	}
  }
  
  provisioner "remote-exec" {
  
	inline = [
      "chmod +x /tmp/provisionVM.sh",
      "/tmp/provisionVM.sh ${var.app_environment}",
    ]
	
	connection {
		type     = "ssh"
		user     = "superadmin"
		private_key = "${var.ssh_private_key}"
	}
  }
}

output "hdfsStorageAccountConnectionString" {
  value = "${azurerm_storage_account.hdfs.primary_connection_string}"
}

output "vmFqdn" {
  value = "${azurerm_public_ip.app.fqdn}"
}