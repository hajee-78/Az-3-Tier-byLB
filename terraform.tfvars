resource_group_name = "development"
location            = "SouthEastAsia"
vnet                = ["192.168.0.0/16"]
web-subnet          = ["192.168.1.0/24"]
app-subnet          = ["192.168.2.0/24"]
db-subnet           = ["192.168.3.0/24"]
AzureBastionSubnet  = ["192.168.4.0/26"]