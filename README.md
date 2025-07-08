# immutable-infra-packer-terraform-azure
This project automates the creation of an Nginx-enabled VM image using Packer, then deploys it on Azure with Terraform, ensuring a consistent and repeatable infrastructure.

## 🔧 Tools Used

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/)
- [Packer](https://developer.hashicorp.com/packer)
- [Terraform](https://developer.hashicorp.com/terraform)

---

## 📁 Folder Structure

immutable-infra-packer-azure-terraform/
├── main.tf                 # Terraform script (creates RG, VNet, NSG, NIC, VM, Public IP)
├── ubuntu-nginx.json       # Packer template to build custom image with Nginx
├── secrets.pkrvars.json    # (Ignored) Holds sensitive Azure credentials
├── .gitignore              # Ignores secrets.pkrvars.json and Terraform state files
├── README.md               # Project documentation
└── terraform.tfstate*      # Terraform state files (auto-generated)


# Step 1: Authenticate to Azure (Service Principal)

Before using Packer or Terraform, authenticate into Azure using a Service Principal with the following command:

az login --service-principal \
  -u "<client_id>" \
  -p "<client_secret>" \
  --tenant "<tenant_id>"

🔒 Replace:

<client_id> with your App Registration / Service Principal ID
<client_secret> with your client secret
<tenant_id> with your Azure Active Directory tenant ID

✅ To confirm you’re logged in:

az account show
💡 You can also store secrets in a separate secrets.pkrvars.json or environment variables for better security.

## 🔑 Step 2: Generate SSH Key (One-Time Setup)
SSH keys are required to log in to the VM created by Terraform.

Generate a secure SSH key pair:

ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

Press Enter to accept the default file path (~/.ssh/id_rsa), and optionally set a passphrase.

Then, copy the public key (id_rsa.pub) into your main.tf file under admin_ssh_key block:

admin_ssh_key {
  username   = "azureuser"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Step 3 : Build Image with Packer

If using variable file(secrets.pkrvars.json):

    packer build -var-file=secrets.pkrvars.json ubuntu-nginx.json

Otherwise:

    packer build ubuntu-nginx.json

# Step 4 : Verify the Image

Navigate to Azure Portal → Resource Group → Image

# Step 5 : Deploy Resources with Terraform

terraform init
terraform plan
terraform apply
Access the VM

After deployment:

🔍 Get the public IP:
terraform output

# Step 6 : Use the public IP from Terraform output

Verify Nginx is running using -

curl http://<your-public-ip>

