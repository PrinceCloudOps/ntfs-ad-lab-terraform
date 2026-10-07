# Hybrid Identity Lab Infrastructure

The Terraform configuration provisions a core virtual network and subnet, a
domain controller (DC01), and a file server (FS01). Both servers connect to
the same subnet, where the NSG association applies the RDP rule. Only DC01 is
configured with a public IP.

```mermaid
graph TD
    RG["Resource Group<br/>RG-Hybrid-Identity-Lab"]

    VNET["Virtual Network<br/>VNet-Core<br/>10.0.0.0/16"]
    SUBNET["Subnet<br/>Subnet-Servers<br/>10.0.1.0/24"]
    RG --> VNET
    VNET --> SUBNET

    PIP["Public IP<br/>pip-dc01"]
    DCNIC["Network Interface<br/>nic-dc01"]
    DC01["Windows VM<br/>DC01"]
    PROMOTE["VM Extension<br/>promote-dc<br/>Promotes to AD DS forest"]
    RG --> PIP
    RG --> DCNIC
    PIP -->|attached to| DCNIC
    SUBNET -->|network interface| DCNIC
    DCNIC -->|attached to| DC01
    RG --> DC01
    DC01 --> PROMOTE

    FSNIC["Network Interface<br/>nic-fs01"]
    FS01["Windows VM<br/>FS01"]
    RG --> FSNIC
    SUBNET -->|network interface| FSNIC
    FSNIC -->|attached to| FS01
    RG --> FS01

    NSG["Network Security Group<br/>NSG-Core<br/>Allow inbound TCP 3389"]
    NSG_ASSOC["Subnet-NSG Association"]
    RG --> NSG
    NSG --> NSG_ASSOC
    NSG_ASSOC -->|applies to| SUBNET
```