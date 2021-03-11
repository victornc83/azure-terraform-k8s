variable "location" {
    type = string
    description = "Región Azure donde vamos a crear los recursos"
    default = "West Europe"
}

variable "nfs_size" {
    type = string
    description = "Tamaño de máquina virtual NFS"
    default = "Standard_D1_v2"
}

variable "vms" {
    type = list(object({
        nombre = string
        grupo = string
        size = string
    }))
    description = "Máquinas virtuales a crear"
    default = [
        {
            nombre = "master1"
            grupo = "master"
            size = "Standard_D2_v2"
        },
        {
            nombre = "worker1"
            grupo = "worker"
            size = "Standard_D1_v2"
        },
        {
            nombre = "worker2"
            grupo = "worker"
            size = "Standard_D1_v2"
        }
    ]
}

variable "k8srules" {
    type = list(object({
        name                       = string
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range          = string
        destination_port_range     = string
        source_address_prefix      = string
        destination_address_prefix = string
    }))
    description = "Reglas de seguridad para kubernetes"
    default = [
        {
            name                       = "SSH"
            priority                   = 1001
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "22"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
        },
        {
            name                       = "K8s_API"
            priority                   = 1002
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "6443"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
        },
        {
            name                       = "K8s_nodeport"
            priority                   = 1003
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "30000-32767"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
        }

    ]
}

variable "nfsrules" {
    type = list(object({
        name                       = string
        priority                   = number
        direction                  = string
        access                     = string
        protocol                   = string
        source_port_range          = string
        destination_port_range     = string
        source_address_prefix      = string
        destination_address_prefix = string
    }))
    description = "Reglas de seguridad para kubernetes"
    default = [
        {
            name                       = "SSH"
            priority                   = 1001
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_port_range          = "*"
            destination_port_range     = "22"
            source_address_prefix      = "*"
            destination_address_prefix = "*"
        }
    ]
}
