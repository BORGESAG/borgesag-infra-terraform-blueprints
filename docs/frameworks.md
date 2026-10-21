# Framework mapping

Every blueprint is reviewed against the same three references: the CIS benchmark for its
provider, NIST (CSF 2.0 for the outcome, SP 800-53 Rev. 5 for the control family) and the
provider's well-architected framework. This file lists the references and the baseline
controls; each blueprint README carries a filled copy of the checklist at the end.

Benchmark versions change often. The checklist records the version used for each review
instead of pinning it here.

## References per provider

| Provider | CIS benchmark | Well-architected framework | Upstream reference |
|---|---|---|---|
| aws | CIS Amazon Web Services Foundations Benchmark | AWS Well-Architected Framework | AWS Security Reference Architecture |
| azure | CIS Microsoft Azure Foundations Benchmark | Azure Well-Architected Framework | Azure Landing Zones, Microsoft Cloud Security Benchmark |
| gcp | CIS Google Cloud Platform Foundation Benchmark | Google Cloud Well-Architected Framework | Google Cloud security foundations (Cloud Foundation Fabric) |
| oci | CIS Oracle Cloud Infrastructure Foundations Benchmark | OCI Well-Architected Framework | OCI Landing Zones (CIS-aligned) |
| proxmox | none for Proxmox VE; CIS Debian Linux Benchmark for the host | not applicable | Proxmox VE admin guide (firewall, users, storage) |

NIST applies to every provider:

- CSF 2.0 functions: Govern (GV), Identify (ID), Protect (PR), Detect (DE), Respond (RS),
  Recover (RC).
- SP 800-53 Rev. 5 families used here: AC (access control), AU (audit), CM (configuration
  management), CP (contingency planning), IA (identification and authentication), SC
  (system and communications protection), SI (system and information integrity).

## Baseline controls

Controls every blueprint must address. "Automated" means a tool in `make lint` fails the
commit when the control is missing; "review" means it is checked by hand and recorded in the
checklist. Custom checkov checks (`policies/checkov`, IDs `CKV_BGS_<NNN>`) turn review items
into automated ones over time.

| ID | Control | NIST CSF | SP 800-53 | WAF pillar | How checked |
|---|---|---|---|---|---|
| B-01 | Least-privilege identities; no wildcard admin policies for workloads | PR.AA | AC-6 | Security | checkov + review |
| B-02 | No long-lived credentials in code, state or variables; secrets from a vault | PR.AA, PR.DS | IA-5 | Security | gitleaks + review |
| B-03 | Encryption at rest on by default (storage, disks, databases, backups) | PR.DS | SC-28 | Security | checkov, trivy |
| B-04 | Encryption in transit; TLS 1.2 or later on public endpoints | PR.DS | SC-8 | Security | checkov, trivy |
| B-05 | No public access by default (buckets, databases, management ports) | PR.IR | AC-3, SC-7 | Security | checkov, trivy |
| B-06 | Network segmentation: private subnets for workloads, ingress only through defined entry points | PR.IR | SC-7 | Security, Reliability | review |
| B-07 | Audit and flow logs enabled and sent to a central destination | DE.CM | AU-2, AU-12 | Operational excellence | checkov + review |
| B-08 | Mandatory tags present (ADR 0004) | ID.AM | CM-8 | Operational excellence, Cost | custom check (planned) |
| B-09 | Backups or snapshots defined with retention; restore documented | RC.RP | CP-9, CP-10 | Reliability | review |
| B-10 | Zone or fault-domain spread where the pattern claims high availability | PR.IR | CP-7 | Reliability | review |
| B-11 | Versions pinned per ADR 0005; no deprecated provider resources | ID.RA | CM-2, SI-2 | Operational excellence | tflint + review |
| B-12 | Cost guardrails: budget or quota, free-tier limits stated for lab blueprints | GV.RM | not mapped | Cost optimization | review |
| B-13 | Deletion protection on stateful resources, off only in examples | PR.DS | CP-9 | Reliability | review |
| B-14 | Destroy path tested at L3, with no orphaned resources | ID.IM | CM-3 | Operational excellence | L3 evidence |

## Exceptions

A blueprint may skip a control only with a written reason in its checklist (for example
"B-10 not applicable: single-node lab"). A checkov or trivy finding is skipped inline with
the check ID and the same reason:

```hcl
resource "oci_objectstorage_bucket" "this" {
  # checkov:skip=CKV_OCI_10:example bucket, public read is the purpose of the example
}
```

Skips without a reason are rejected in review.

## Blueprint checklist

Copy this block to the end of each blueprint README and fill it in.

```markdown
## Compliance checklist

Reviewed: YYYY-MM-DD. Validation level: L1 | L2 | L3.
References: CIS <benchmark name> vX.Y.Z; NIST CSF 2.0; NIST SP 800-53 Rev. 5;
<provider> Well-Architected Framework.

| ID | Status | Evidence or reason |
|---|---|---|
| B-01 | met / partial / n/a | |
| B-02 | | |
| B-03 | | |
| B-04 | | |
| B-05 | | |
| B-06 | | |
| B-07 | | |
| B-08 | | |
| B-09 | | |
| B-10 | | |
| B-11 | | |
| B-12 | | |
| B-13 | | |
| B-14 | | |

CIS recommendations covered beyond the baseline: <list of CIS IDs, or none>.
Open items: <list, or none>.
```
