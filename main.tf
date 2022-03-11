#Firewall instances
resource "aviatrix_firewall_instance" "firewall_instance" {
  count                  = local.ha_gw ? 0 : (local.is_aviatrix ? 0 : 1) #If ha is false, and is_aviatrix is false, deploy 1
  firewall_name          = coalesce(var.custom_fw_names[count.index], "${local.name}-fw")
  firewall_size          = local.instance_size
  vpc_id                 = local.vpc.vpc_id
  firewall_image         = var.firewall_image
  firewall_image_version = local.firewall_image_version
  egress_subnet          = local.egress_subnet_1
  firenet_gw_name        = local.transit_gateway.gw_name
  iam_role               = var.iam_role_1
  bootstrap_bucket_name  = var.bootstrap_bucket_name_1
  management_subnet      = local.is_palo ? local.vpc.subnets[0].cidr : null
  zone                   = var.use_gwlb ? local.az1 : null
  firewall_image_id      = var.firewall_image_id
  user_data              = var.user_data_1
  tags                   = var.fw_tags
  username               = local.username
}

resource "aviatrix_firewall_instance" "firewall_instance_1" {
  count                  = local.ha_gw ? (local.is_aviatrix ? 0 : var.fw_amount / 2) : 0 #If ha is true, and is_aviatrix is false, deploy var.fw_amount / 2
  firewall_name          = coalesce(var.custom_fw_names[count.index], "${local.name}-az1-fw${count.index + 1}")
  firewall_size          = local.instance_size
  vpc_id                 = local.vpc.vpc_id
  firewall_image         = var.firewall_image
  firewall_image_version = local.firewall_image_version
  egress_subnet          = local.egress_subnet_1
  firenet_gw_name        = local.transit_gateway.gw_name
  iam_role               = var.iam_role_1
  bootstrap_bucket_name  = var.bootstrap_bucket_name_1
  management_subnet      = local.is_palo ? local.vpc.subnets[0].cidr : null
  zone                   = var.use_gwlb ? local.az1 : null
  firewall_image_id      = var.firewall_image_id
  user_data              = var.user_data_1
  tags                   = var.fw_tags
  username               = local.username
}

resource "aviatrix_firewall_instance" "firewall_instance_2" {
  count                  = local.ha_gw ? (local.is_aviatrix ? 0 : var.fw_amount / 2) : 0 #If ha is true, and is_aviatrix is false, deploy var.fw_amount / 2
  firewall_name          = coalesce(var.custom_fw_names[length(var.custom_fw_names) / 2 + count.index], "${local.name}-az2-fw${count.index + 1}")
  firewall_size          = local.instance_size
  vpc_id                 = local.vpc.vpc_id
  firewall_image         = var.firewall_image
  firewall_image_version = local.firewall_image_version
  egress_subnet          = local.egress_subnet_2
  firenet_gw_name        = local.transit_gateway.ha_gw_name
  iam_role               = local.iam_role_2
  bootstrap_bucket_name  = local.bootstrap_bucket_name_2
  management_subnet      = local.is_palo ? (local.single_az_mode ? local.vpc.subnets[0].cidr : local.vpc.subnets[2].cidr) : null
  zone                   = var.use_gwlb ? local.az2 : null
  firewall_image_id      = var.firewall_image_id
  user_data              = local.user_data_2
  tags                   = var.fw_tags
  username               = local.username
}

#FQDN Egress filtering instances
resource "aviatrix_gateway" "egress_instance" {
  count        = local.ha_gw ? 0 : (local.is_aviatrix ? 1 : 0) #If ha is false, and is_aviatrix is true, deploy 1
  cloud_type   = 1
  account_name = local.account
  gw_name      = coalesce(var.custom_fw_names[count.index], "${local.name}-egress-gw")
  vpc_id       = local.vpc.vpc_id
  vpc_reg      = local.region
  gw_size      = local.instance_size
  subnet       = local.vpc.subnets[1].cidr
  single_az_ha = local.single_az_ha
  tags         = var.fw_tags
}

resource "aviatrix_gateway" "egress_instance_1" {
  count        = local.ha_gw ? (local.is_aviatrix ? var.fw_amount / 2 : 0) : 0 #If ha is true, and is_aviatrix is true, deploy var.fw_amount / 2
  cloud_type   = 1
  account_name = local.account
  gw_name      = coalesce(var.custom_fw_names[count.index], "${local.name}-az1-egress-gw${count.index + 1}")
  vpc_id       = local.vpc.vpc_id
  vpc_reg      = local.region
  gw_size      = local.instance_size
  subnet       = local.vpc.subnets[1].cidr
  single_az_ha = local.single_az_ha
  tags         = var.fw_tags
}

resource "aviatrix_gateway" "egress_instance_2" {
  count        = local.ha_gw ? (local.is_aviatrix ? var.fw_amount / 2 : 0) : 0 #If ha is true, and is_aviatrix is true, deploy var.fw_amount / 2
  cloud_type   = 1
  account_name = local.account
  gw_name      = coalesce(var.custom_fw_names[length(var.custom_fw_names) / 2 + count.index], "${local.name}-az2-egress-gw${count.index + 1}")
  vpc_id       = local.vpc.vpc_id
  vpc_reg      = local.region
  gw_size      = local.instance_size
  subnet       = local.single_az_mode ? local.vpc.subnets[1].cidr : local.vpc.subnets[3].cidr
  single_az_ha = local.single_az_ha
  tags         = var.fw_tags
}

#Firenet
resource "aviatrix_firenet" "firenet" {
  vpc_id                               = local.vpc.vpc_id
  inspection_enabled                   = local.is_aviatrix || local.enable_egress_transit_firenet ? false : var.inspection_enabled #Always switch to false if Aviatrix FQDN egress or egress transit firenet.
  egress_enabled                       = local.is_aviatrix || local.enable_egress_transit_firenet ? true : var.egress_enabled      #Always switch to true if Aviatrix FQDN egress or egress transit firenet.
  keep_alive_via_lan_interface_enabled = var.keep_alive_via_lan_interface_enabled
  manage_firewall_instance_association = false
  egress_static_cidrs                  = var.egress_static_cidrs
  fail_close_enabled                   = var.fail_close_enabled
  east_west_inspection_excluded_cidrs  = var.east_west_inspection_excluded_cidrs

  depends_on = [
    aviatrix_firewall_instance_association.firenet_instance1,
    aviatrix_firewall_instance_association.firenet_instance2,
    aviatrix_firewall_instance_association.firenet_instance,
    aviatrix_gateway.egress_instance,
    aviatrix_gateway.egress_instance_1,
    aviatrix_gateway.egress_instance_2,
  ]
}

resource "aviatrix_firewall_instance_association" "firenet_instance" {
  count                = local.ha_gw ? 0 : 1
  vpc_id               = local.vpc.vpc_id
  firenet_gw_name      = local.transit_gateway.gw_name
  instance_id          = local.is_aviatrix ? aviatrix_gateway.egress_instance[0].gw_name : aviatrix_firewall_instance.firewall_instance[0].instance_id
  firewall_name        = local.is_aviatrix ? null : aviatrix_firewall_instance.firewall_instance[0].firewall_name
  lan_interface        = local.is_aviatrix ? null : aviatrix_firewall_instance.firewall_instance[0].lan_interface
  management_interface = local.is_aviatrix ? null : aviatrix_firewall_instance.firewall_instance[0].management_interface
  egress_interface     = local.is_aviatrix ? null : aviatrix_firewall_instance.firewall_instance[0].egress_interface
  vendor_type          = local.is_aviatrix ? "fqdn_gateway" : null
  attached             = var.attached
}

resource "aviatrix_firewall_instance_association" "firenet_instance1" {
  count                = local.ha_gw ? var.fw_amount / 2 : 0
  vpc_id               = local.vpc.vpc_id
  firenet_gw_name      = local.transit_gateway.gw_name
  instance_id          = local.is_aviatrix ? aviatrix_gateway.egress_instance_1[count.index].gw_name : aviatrix_firewall_instance.firewall_instance_1[count.index].instance_id
  firewall_name        = local.is_aviatrix ? null : aviatrix_firewall_instance.firewall_instance_1[count.index].firewall_name
  lan_interface        = local.is_aviatrix ? null : aviatrix_firewall_instance.firewall_instance_1[count.index].lan_interface
  management_interface = local.is_aviatrix ? null : aviatrix_firewall_instance.firewall_instance_1[count.index].management_interface
  egress_interface     = local.is_aviatrix ? null : aviatrix_firewall_instance.firewall_instance_1[count.index].egress_interface
  vendor_type          = local.is_aviatrix ? "fqdn_gateway" : null
  attached             = var.attached
}

resource "aviatrix_firewall_instance_association" "firenet_instance2" {
  count                = local.ha_gw ? var.fw_amount / 2 : 0
  vpc_id               = local.vpc.vpc_id
  firenet_gw_name      = local.transit_gateway.ha_gw_name
  instance_id          = local.is_aviatrix ? aviatrix_gateway.egress_instance_2[count.index].gw_name : aviatrix_firewall_instance.firewall_instance_2[count.index].instance_id
  firewall_name        = local.is_aviatrix ? null : aviatrix_firewall_instance.firewall_instance_2[count.index].firewall_name
  lan_interface        = local.is_aviatrix ? null : aviatrix_firewall_instance.firewall_instance_2[count.index].lan_interface
  management_interface = local.is_aviatrix ? null : aviatrix_firewall_instance.firewall_instance_2[count.index].management_interface
  egress_interface     = local.is_aviatrix ? null : aviatrix_firewall_instance.firewall_instance_2[count.index].egress_interface
  vendor_type          = local.is_aviatrix ? "fqdn_gateway" : null
  attached             = var.attached
}
