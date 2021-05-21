# Despliegue de cluster k8s en Azure

### Estructura del proyecto

```
  - terraform
     |__ vars.tf           # Definición de variables
     |__ main.tf           # Definición de resource group
     |__ security.tf       # Definición de security groups 
     |__ network.tf        # Definición de elementos de red
     |__ vm.tf             # Definición de máquinas virtuales
     |
  - ansible
     |__ roles                     # Colección de roles          
     |    |__ nfs                  # Rol configuración NFS
     |    |__ kubernetes           # Rol configurción cluster K8s
     |    |__ app                  # Rol de despliegue de aplicación
     |
     |__ enviro                    # Colección de inventarios
     |    |__ cp2.azure_rm.yaml    # inventario dinámico con plugin azure_rm
     |    |__ cp2.local            # inventario entorno local
     |
     |__ group_vars                # Definición de variables de grupo
     |    |...    
     |
     |__ ansible.cfg               # fichero de configuración de Ansible
     |__ playbook.yaml             # playbook de ejecución

```

### Despliegue infraestructura con Terraform

Primero logarse en Azure con ayuda del propio cliente:
```bash
$ az login

[
  {
    "cloudName": "AzureCloud",
    "id": "00000000-0000-0000-0000-000000000000",
    "isDefault": true,
    "name": "PAYG Subscription",
    "state": "Enabled",
    "tenantId": "00000000-0000-0000-0000-000000000000",
    "user": {
      "name": "user@example.com",
      "type": "user"
    }
  }
]
```

Escogemos el ```id``` como nuestros ```subscription_id``` que nos será de utilidad para continuar con la configuración del entorno.

Seguidamente creamos un ```client_id```y ```client_secret```. Para ello ejecutamos los siguientes comandos:

```bash
$ az account set --subscription="SUBSCRIPTION_ID"

$ az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/SUBSCRIPTION_ID"

{
  "appId": "00000000-0000-0000-0000-000000000000",
  "displayName": "azure-cli-2017-06-05-10-41-15",
  "name": "http://azure-cli-2017-06-05-10-41-15",
  "password": "0000-0000-0000-0000-000000000000",
  "tenant": "00000000-0000-0000-0000-000000000000"
}
```

Teniendo en cuenta de que:

- ```appId``` se corresponde con ```client_id```
- ```password``` se corresponde con ```client_secret```
- ```tenant``` se corresponde con ```tenant_id```

Declaramos las variables de entorno necesarias para la ejecución de terraform:

```bash
$ export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
$ export ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
$ export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
$ export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
```

Dentro de la carpeta ```terraform``` procedemos a validar el código:
```bash
~/terraform/$ terraform validate

Template interpolation syntax is still used to construct strings from
expressions when the template includes multiple interpolation sequences or a
mixture of literal strings and interpolations. This deprecation applies only
to templates that consist entirely of a single interpolation sequence.

Success! The configuration is valid, but there were some validation warnings as shown above.
```

Y aplicamos la configuración.

```bash
~/terraform/$ terraform apply

...
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

```

Cuando termine de crear los recursos en Azure terraform nos saca un informe de las tareas realizadas:

```bash
Apply complete! Resources: 6 added, 3 changed, 4 destroyed.
```

### Despliegue del cluster k8s vanilla con Ansible

A partir de ahora trabajaremos dentro de la carpeta ```ansible```.

Primero validar que conectamos correctamente con Azure para generar el inventario dinamico.

```
~/ansible/$ ansible-inventory -i ./enviro/cp2.azure_rm.yaml --list

...
    },
    "all": {
        "children": [
            "group_master",
            "group_nfs",
            "group_worker",
            "ungrouped"
        ]
    },
    "group_master": {
        "hosts": [
            "vm-master1_d3e0"
        ]
    },
    "group_nfs": {
        "hosts": [
            "vm-nfs_afd4"
        ]
    },
    "group_worker": {
        "hosts": [
            "vm-worker1_eacb"
        ]
    }
}
```

Vamos a probar a lanzar algún comando adhoc con Ansible:

```
~/ansible/$ ansible -i ./enviro/cp2.azure_rm.yaml -u devops -m ping all

vm-worker1_eacb | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}
vm-master1_d3e0 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}
vm-nfs_afd4 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}
```

Ya estamos listos para lanzar el playbook de instalación del cluster, vamos a echarle un vistazo al playbook:

playbook.yaml
```
---
- hosts: all
  remote_user: devops
  become: true
  roles:
    - nfs

- hosts: group_master:group_worker
  remote_user: devops
  roles:
    - kubernetes

- hosts: group_master[0]
  remote_user: devops
  roles: 
    - app
```

Para ejecutarlo bastaría con ejecutar ```ansible-playbook```:

```bash
~/ansible/$ ansible-playbook -i enviro/cp2.azure_rm.yaml playbook.yaml 
```

### Probando la aplicación
En el mismo proceso de despliegue de la aplicación dentro del cluster se ha introducido una serie de tareas para validar que todo ha ido correctamente. En cualquier caso, puede surgir la necesidad realizar pruebas para asegurar el correcto funcionamiento.

1) Accedemos al master, con el usuario no-root, configurado para atacar el API de K8s.
2) Obtenemos información sobre el servicio vinculado con el HAProxy Ingress Controller.
```bash
$ kubectl get svc -n haproxy-controller -o wide

NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                                     AGE    SELECTOR
haproxy-ingress           NodePort    10.108.30.152    <none>        80:31519/TCP,443:31161/TCP,1024:30685/TCP   174m   run=haproxy-ingress
ingress-default-backend   ClusterIP   10.106.105.138   <none>        8080/TCP                                    174m   run=ingress-default-backend
```
3) Desde la máquina local ya podríamos probar a invocar un cUrl a la ip publica de cualquiera de los nodos del cluster. 

```bash
$ curl -I -H 'Host: cp2-app.bar' http://168.63.10.41:31519/app

HTTP/1.1 200 OK
server: nginx/1.8.0
date: Wed, 10 Mar 2021 03:49:32 GMT
content-type: text/html
content-length: 3988
last-modified: Mon, 03 Aug 2015 00:27:03 GMT
etag: "55beb557-f94"
accept-ranges: bytes
```
