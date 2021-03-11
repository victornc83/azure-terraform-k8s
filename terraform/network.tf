# Creación de red
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network

resource "azurerm_virtual_network" "myNet" {
    name                = "kubernetesnet"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    tags = {
        environment = "CasoPractico2"
    }
}

# Creación de subnet
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "mySubnet" {
    name                   = "terraformsubnet"
    resource_group_name    = azurerm_resource_group.rg.name
    virtual_network_name   = azurerm_virtual_network.myNet.name
    address_prefixes       = ["10.0.1.0/24"]

}

# K8s - Nics
resource "azurerm_network_interface" "k8sNic" {
    count               = length(var.vms)
    name                = "vmnic-${var.vms[count.index].nombre}"  
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
        name                           = "ipconf-${var.vms[count.index].nombre}"
        subnet_id                      = azurerm_subnet.mySubnet.id 
        private_ip_address_allocation  = "Static"
        private_ip_address             = "10.0.1.${count.index+10}"
        public_ip_address_id           = azurerm_public_ip.k8sPublicIp[count.index].id
    }

    tags = {
        environment = "CasoPractico2"
    }

}

# NFS server - Nic
resource "azurerm_network_interface" "nfsNic" {
    name                = "vmnic-nfs"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
        name            = "ipconf-nfs"
        subnet_id                      = azurerm_subnet.mySubnet.id 
        private_ip_address_allocation  = "Static"
        private_ip_address             = "10.0.1.100"
        public_ip_address_id           = azurerm_public_ip.nfsPublicIp.id
    }

    tags = {
      environment = "CasoPractico2"
    }
}

# K8s - IP pública
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip
resource "azurerm_public_ip" "k8sPublicIp" {
    count               = length(var.vms)
    name                = "myIp-${var.vms[count.index].nombre}"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = "Dynamic"
    sku                 = "Basic"

    tags = {
        environment = "CasoPractico2"
    }
}

# NFS server - IP pública
resource "azurerm_public_ip" "nfsPublicIp" {
    name                = "myIp-nfs"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method   = "Dynamic"
    sku                 = "Basic"
}