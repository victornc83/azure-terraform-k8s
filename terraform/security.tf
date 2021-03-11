# k8s Security group
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group

resource "azurerm_network_security_group" "k8sSecGroup" {
    name                = "k8sSecGroup"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    tags = {
        environment = "CP2"
    }
}

# k8s - Security rules
resource "azurerm_network_security_rule" "k8sSecRule" {
    count                       = length(var.k8srules)
    name                        = var.k8srules[count.index].name
    direction                   = var.k8srules[count.index].direction
    access                      = var.k8srules[count.index].access
    priority                    = var.k8srules[count.index].priority
    protocol                    = var.k8srules[count.index].protocol
    source_port_range           = var.k8srules[count.index].source_port_range
    destination_port_range      = var.k8srules[count.index].destination_port_range
    source_address_prefix       = var.k8srules[count.index].source_address_prefix
    destination_address_prefix  = var.k8srules[count.index].destination_address_prefix
    resource_group_name         = azurerm_resource_group.rg.name
    network_security_group_name = azurerm_network_security_group.k8sSecGroup.name
}

# Vinculamos el security group al interface de red de las máquinas del cluster K8s
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association
resource "azurerm_network_interface_security_group_association" "k8sGroupAssociation" {
    count                     = length(var.vms)
    network_interface_id      = azurerm_network_interface.k8sNic[count.index].id
    network_security_group_id = azurerm_network_security_group.k8sSecGroup.id

}

# NFS server security group 
resource "azurerm_network_security_group" "nfsSecGroup" {
    name                = "nfsSecGroup"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    tags = {
        environment = "CP2"
    }
}

# NFS server security rules
resource "azurerm_network_security_rule" "nfsSecRule" {
    count                       = length(var.nfsrules)
    name                        = var.nfsrules[count.index].name
    direction                   = var.nfsrules[count.index].direction
    access                      = var.nfsrules[count.index].access
    priority                    = var.nfsrules[count.index].priority
    protocol                    = var.nfsrules[count.index].protocol
    source_port_range           = var.nfsrules[count.index].source_port_range
    destination_port_range      = var.nfsrules[count.index].destination_port_range
    source_address_prefix       = var.nfsrules[count.index].source_address_prefix
    destination_address_prefix  = var.nfsrules[count.index].destination_address_prefix
    resource_group_name         = azurerm_resource_group.rg.name
    network_security_group_name = azurerm_network_security_group.nfsSecGroup.name
}

# Vinculamos el security group al interface de red de la máquina del NFS 
resource "azurerm_network_interface_security_group_association" "nfsGroupAssociation" {
    network_interface_id      = azurerm_network_interface.nfsNic.id
    network_security_group_id = azurerm_network_security_group.nfsSecGroup.id

}