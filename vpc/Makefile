help:		## Print Help Message
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

clean:
	@rm -rf .terraform*

dev-apply:	clean ## Install Frontend Component
	@terraform init -backend-config=environments/dev-backend.tfvars -no-color
	@terraform apply -auto-approve -var-file=environments/dev.tfvars -no-color

prod-apply:	clean ## Install Frontend Component
	@terraform init -backend-config=environments/prod-backend.tfvars -no-color
	@terraform apply -auto-approve -var-file=environments/prod.tfvars -no-color

dev-destroy:	clean ## Install Frontend Component
	@terraform init -backend-config=environments/dev-backend.tfvars -no-color
	@terraform destroy -auto-approve -var-file=environments/dev.tfvars -no-color

prod-destroy:	clean ## Install Frontend Component
	@terraform init -backend-config=environments/prod-backend.tfvars -no-color
	@terraform destroy -auto-approve -var-file=environments/prod.tfvars -no-color

