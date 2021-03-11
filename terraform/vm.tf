# Creamos una máquina virtual
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine

# K8s cluster virtual machines
resource "azurerm_linux_virtual_machine" "k8s" {
    count               = length(var.vms)
    name                = "vm-${var.vms[count.index].nombre}"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    size                = var.vms[count.index].size
    admin_username      = "devops"
    network_interface_ids = [ azurerm_network_interface.k8sNic[count.index].id ]
    disable_password_authentication = true

    admin_ssh_key {
        username   = "devops"
        public_key = file("~/.ssh/id_rsa.pub")
    }

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    plan {
        name      = "centos-8-stream-free"
        product   = "centos-8-stream-free"
        publisher = "cognosys"
    }

    source_image_reference {
        publisher = "cognosys"
        offer     = "centos-8-stream-free"
        sku       = "centos-8-stream-free"
        version   = "1.2019.0810"
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.stAccount.primary_blob_endpoint
    }

    tags = {
        environment = "CasoPractico2"
        group = "${var.vms[count.index].grupo}"
    }

}

# NFS server virtual machine

resource "azurerm_linux_virtual_machine" "nfs" {
    name                = "vm-nfs"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    size                = var.nfs_size
    admin_username      = "devops"
    network_interface_ids = [ azurerm_network_interface.nfsNic.id ]
    disable_password_authentication = true

    admin_ssh_key {
        username   = "devops"
        public_key = file("~/.ssh/id_rsa.pub")
    }

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    plan {
        name      = "centos-8-stream-free"
        product   = "centos-8-stream-free"
        publisher = "cognosys"
    }

    source_image_reference {
        publisher = "cognosys"
        offer     = "centos-8-stream-free"
        sku       = "centos-8-stream-free"
        version   = "1.2019.0810"
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.stAccount.primary_blob_endpoint
    }

    tags = {
        environment = "CasoPractico2"
        group = "nfs"
    }

}

resource "azurerm_managed_disk" "nfsDataDisk" {
    name                 = "nfs-data-disk"
    location             = azurerm_resource_group.rg.location
    resource_group_name  = azurerm_resource_group.rg.name
    storage_account_type = "Standard_LRS"
    create_option        = "Empty"
    disk_size_gb         = 10

    tags = {
        environment = "CasoPractico2"
    }
}

resource "azurerm_virtual_machine_data_disk_attachment" "nfsDiskAttach" {
    managed_disk_id       = azurerm_managed_disk.nfsDataDisk.id
    virtual_machine_id    = azurerm_linux_virtual_machine.nfs.id
    lun                   = "10"
    caching               = "ReadWrite"
}

