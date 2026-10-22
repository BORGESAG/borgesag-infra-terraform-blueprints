# Pure computation, no provider: names and standard tags from one set of inputs (ADR 0004).

locals {
  # OCI region keys from the Oracle documentation (checked 2026-10-21). Other providers
  # have no official short codes: pass region_code.
  oci_region_keys = {
    "af-johannesburg-1" = "jnb"
    "ap-chuncheon-1"    = "yny"
    "ap-hyderabad-1"    = "hyd"
    "ap-melbourne-1"    = "mel"
    "ap-mumbai-1"       = "bom"
    "ap-osaka-1"        = "kix"
    "ap-seoul-1"        = "icn"
    "ap-singapore-1"    = "sin"
    "ap-sydney-1"       = "syd"
    "ap-tokyo-1"        = "nrt"
    "ca-montreal-1"     = "yul"
    "ca-toronto-1"      = "yyz"
    "eu-amsterdam-1"    = "ams"
    "eu-frankfurt-1"    = "fra"
    "eu-madrid-1"       = "mad"
    "eu-marseille-1"    = "mrs"
    "eu-milan-1"        = "lin"
    "eu-paris-1"        = "cdg"
    "eu-stockholm-1"    = "arn"
    "eu-zurich-1"       = "zrh"
    "il-jerusalem-1"    = "mtz"
    "me-abudhabi-1"     = "auh"
    "me-dubai-1"        = "dxb"
    "me-jeddah-1"       = "jed"
    "me-riyadh-1"       = "ruh"
    "mx-monterrey-1"    = "mty"
    "mx-queretaro-1"    = "qro"
    "sa-bogota-1"       = "bog"
    "sa-santiago-1"     = "scl"
    "sa-saopaulo-1"     = "gru"
    "sa-valparaiso-1"   = "vap"
    "sa-vinhedo-1"      = "vcp"
    "uk-cardiff-1"      = "cwl"
    "uk-london-1"       = "lhr"
    "us-ashburn-1"      = "iad"
    "us-chicago-1"      = "ord"
    "us-phoenix-1"      = "phx"
    "us-sanjose-1"      = "sjc"
  }

  region_code = coalesce(
    var.region_code,
    var.provider_name == "oci" ? lookup(local.oci_region_keys, var.region, null) : null,
    "__missing__"
  )

  prefix = "${var.org}-${var.workload}-${var.environment}-${local.region_code}"

  # Resource type abbreviations shared by every module (ADR 0004).
  abbreviations = {
    block_volume           = "bv"
    bucket                 = "bkt"
    internet_gateway       = "igw"
    instance               = "vm"
    kubernetes_cluster     = "k8s"
    load_balancer          = "lb"
    nat_gateway            = "ngw"
    network_security_group = "nsg"
    route_table            = "rt"
    security_list          = "sl"
    service_gateway        = "sgw"
    subnet                 = "snet"
    vault                  = "kv"
    vcn                    = "vcn"
    vnic                   = "vnic"
    volume_attachment      = "att"
  }

  standard_tags = {
    "owner"               = var.owner
    "workload"            = var.workload
    "environment"         = var.environment
    "cost-center"         = var.cost_center
    "data-classification" = var.data_classification
    "criticality"         = var.criticality
    "source"              = var.source_path
    "managed-by"          = "terraform"
  }

  tags = merge(var.extra_tags, local.standard_tags)
}
