.PHONY: init
# ── Initialize ──────────────────────────────────────────────────────────
init:
	@echo "🔗 Symlinking shared terraform.tfvars..."
	@ln -sf ../terraform.tfvars terraform/base/terraform.tfvars
	@ln -sf ../terraform.tfvars terraform/cluster/terraform.tfvars

	cd terraform/base && terraform init
	cd terraform/cluster && terraform init

.PHONY: create-base
# ── First Run: Create Base Template (VM 9000) ───────────────────────────
create-base:
	@echo "🏗️  Creating base template..."
	@TMPDIR=$$(mktemp -d) && \
    trap 'rm -rf "$$TMPDIR"' EXIT; \
    ssh-keygen -t ed25519 -f "$$TMPDIR/pkr_key" -N '' -q && \
    packer init packer && \
    cd packer && packer build \
    -var "build_ssh_public_key=$$(cat $$TMPDIR/pkr_key.pub)" \
    -var "build_ssh_private_key_path=$$TMPDIR/pkr_key" .

.PHONY: create-cluster
# ── Deploy K3s Cluster ──────────────────────────────────────────────────
create-cluster:
	@echo "🚀 Deploying K3s cluster..."
	cd terraform/cluster && terraform apply -auto-approve

.PHONY: destroy-base
# ── Cleanup Base Template ───────────────────────────────────────────────
destroy-base:
	@echo "🗑️  Removing base template..."
	cd terraform/base && terraform destroy -auto-approve
	ssh root@$(shell grep "proxmox_host" terraform/base/terraform.tfvars | cut -d'"' -f2) \
		"qm destroy 9000 --destroy-unreferenced-disks --skip-lock true" || true

.PHONY: destroy-cluster
# ── Destroy K3s Cluster ─────────────────────────────────────────────────
destroy-cluster:
	@echo "🔥 Destroying K3s cluster..."
	cd terraform/cluster && terraform destroy -auto-approve

.PHONY: clean
# ── Clean Everything ────────────────────────────────────────────────────
clean: destroy-cluster destroy-base
	rm -rf terraform/base/terraform.tfstate* terraform/base/terraform.tfvars
	rm -rf terraform/cluster/terraform.tfstate* terraform/cluster/terraform.tfvars
