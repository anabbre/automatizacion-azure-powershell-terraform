# Proveedor de Azure. En esta sección indicamos que vamos a usar el proveedor de Azure
# y configuramos la suscripción que vamos a utilizar con el ID de suscripción de Azure.
provider "azurerm" {
  features {}  # Esto activa las características básicas del proveedor de Azure
  
  # Aquí debes poner el ID de tu suscripción de Azure.
  subscription_id = "tu_id_de_suscripción"  # Sustituir por el ID de tu suscripción
}

# Creación del grupo de recursos. Un grupo de recursos es un contenedor
# donde se almacenan los recursos de Azure. Lo hemos llamado "example-resources" 
# y lo colocamos en la región "East US".
resource "azurerm_resource_group" "example" {
  name     = "example-resources"  # Puedes cambiar el nombre del grupo de recursos
  location = "East US"  # Puedes cambiar la ubicación de la región si lo deseas
}

# Creamos una red virtual en Azure, la cual actúa como una red privada
# en la que se pueden agregar máquinas virtuales. En este caso, asignamos un rango de direcciones IP
# "10.0.0.0/16", y lo asociamos al grupo de recursos y la ubicación previamente definidos.
resource "azurerm_virtual_network" "example" {
  name                = "example-network"  # Cambiar el nombre de la red virtual
  address_space        = ["10.0.0.0/16"]    # Cambiar el rango de direcciones IP si es necesario
  location            = azurerm_resource_group.example.location  # Usamos la ubicación del grupo de recursos
  resource_group_name = azurerm_resource_group.example.name  # Asociamos la red al grupo de recursos
}

# Creamos una subred dentro de la red virtual. La subred tiene un rango de direcciones IP 
# "10.0.1.0/24". La asociamos a la red virtual y al grupo de recursos de antes.
resource "azurerm_subnet" "example" {
  name                 = "internal"  # Nombre de la subred
  resource_group_name  = azurerm_resource_group.example.name  # Asociamos al grupo de recursos
  virtual_network_name = azurerm_virtual_network.example.name  # Asociamos a la red virtual creada anteriormente
  address_prefixes     = ["10.0.1.0/24"]  # Rango de direcciones IP para la subred
}

# Creamos una interfaz de red, la cual se usa para conectar las máquinas virtuales a la red.
# En este caso, la interfaz está asociada a la subred "internal" y tendrá una IP privada asignada dinámicamente.
resource "azurerm_network_interface" "example" {
  name                = "example-nic"  # Nombre de la interfaz de red
  location            = azurerm_resource_group.example.location  # Ubicación de la interfaz de red
  resource_group_name = azurerm_resource_group.example.name  # Asociamos a nuestro grupo de recursos

  # Configuración de la interfaz de red
  ip_configuration {
    name                          = "example-ip-config"  # Nombre de la configuración IP
    subnet_id                     = azurerm_subnet.example.id  # Asociamos a la subred
    private_ip_address_allocation = "Dynamic"  # La IP se asigna dinámicamente
  }
}

# Creamos una IP pública para la máquina virtual. Esta dirección se usa para que la VM sea accesible desde Internet.
# La IP es asignada dinámicamente.
resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"  # Nombre de la IP pública
  location            = azurerm_resource_group.example.location  # Ubicación de la IP pública
  resource_group_name = azurerm_resource_group.example.name  # Asociamos al grupo de recursos
  allocation_method = "Static"  # Asignación estática de IP pública
}

# Finalmente, creamos la máquina virtual. Esta máquina virtual se conectará a la red interna, 
# y utilizará la imagen "UbuntuServer" de Canonical. El tamaño de la máquina es "Standard_B1s".
# La configuración de la VM incluye el nombre de usuario y la contraseña.
resource "azurerm_virtual_machine" "example" {
  name                  = "example-vm"  # Nombre de la máquina virtual
  location              = azurerm_resource_group.example.location  # Ubicación de la VM
  resource_group_name   = azurerm_resource_group.example.name  # Asociamos al grupo de recursos
  network_interface_ids = [azurerm_network_interface.example.id]  # Asociamos la interfaz de red
  vm_size               = "Standard_B1s"  # Tamaño de la máquina virtual

  # Configuración del disco OS (sistema operativo)
  storage_os_disk {
    name              = "example-os-disk"  # Nombre del disco del sistema operativo
    caching           = "ReadWrite"  # Política de caché para el disco
    create_option     = "FromImage"  # Usamos una imagen para crear el disco
    managed_disk_type = "Standard_LRS"  # Tipo de disco administrado (por ejemplo, Standard_LRS)
    os_type           = "Linux"  # El sistema operativo de la máquina es Linux
  }

  # Configuración de la imagen de la máquina virtual
  storage_image_reference {
    publisher = "Canonical"  # Publicador de la imagen
    offer     = "UbuntuServer"  # Ofrecemos la imagen de Ubuntu Server
    sku       = "18.04-LTS"  # Versión de la imagen
    version   = "latest"  # Usamos la última versión disponible
  }

  # Configuración del perfil del sistema operativo
  os_profile {
    computer_name  = "hostname"  # Nombre del host de la máquina virtual
    admin_username = "adminuser"  # Nombre de usuario de administrador
    admin_password = var.admin_password  # Aquí se usa una variable para la contraseña de administrador
  }

  # Configuración específica para máquinas virtuales Linux
  os_profile_linux_config {
    disable_password_authentication = false  # Habilitamos la autenticación por contraseña
  }
}
