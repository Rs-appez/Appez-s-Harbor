.PHONY: init apply-base apply-cluster destroy-base destroy-cluster clean

# ── Initialize ──────────────────────────────────────────────────────────
init:
	cd terraform && terraform init

# ── First Run: Create Base Template (VM 9000) ───────────────────────────
apply-base:
	@echo "🛠️  Enabling snippets content type on Proxmox storage..."
	ssh proxmox "pvesm set local --content iso,vztmpl,backup,import,snippets"

	@echo "📦 Creating base template (VM 9000)..."
	cd terraform && \
		terraform apply -target="proxmox_virtual_environment_download_file.alpine_cloud" -auto-approve && \
		terraform apply -target="proxmox_virtual_environment_vm.alpine_template" -auto-approve && \
		terraform apply -auto-approve && \
		terraform output -raw base_setup_status

# ── Deploy K3s Cluster ──────────────────────────────────────────────────
apply-cluster:
	@echo "🚀 Deploying K3s cluster..."
	cd terraform && terraform apply -auto-approve

# ── Cleanup Base Template ───────────────────────────────────────────────
destroy-base:
	@echo "🗑️  Removing base template..."
	ssh root@$(shell grep "proxmox_host" terraform/terraform.tfvars | cut -d'"' -f2) \
		"qm destroy 9000 --destroy-unreferenced-disks --skip-lock true"

# ── Destroy K3s Cluster ─────────────────────────────────────────────────
destroy-cluster:
	cd terraform && terraform destroy -auto-approve

# ── Clean Everything ────────────────────────────────────────────────────
clean: destroy-base destroy-cluster
	rm -rf terraform/terraform.tfstate*
