# staging environment backend resources details
ifeq ($(filter staging,$(MAKECMDGOALS)),staging)
PROFILE_NAME = ${TF_STAGING_PROFILE_NAME}
BUCKET_NAME = ${TF_STAGING_BUCKET_NAME}
DYNAMODB_TABLE_NAME = ${TF_STAGING_DYNAMODB_TABLE_NAME}
REGION = ${TF_STAGING_REGION}
ROLE_NAME = ${TF_STAGING_IAM_ROLE_NAME}
ROLE_DOC = '$(shell echo $${TF_STAGING_IAM_ROLE_DOC})'
POLICY_NAME = ${TF_STAGING_IAM_POLICY_NAME}
POLICY_DOC = '$(shell echo $${TF_STAGING_IAM_POLICY_DOC})'
endif

# production environment backend resources details
ifeq ($(filter production,$(MAKECMDGOALS)),production)
PROFILE_NAME = ${TF_PROD_PROFILE_NAME}
BUCKET_NAME = ${TF_PROD_BUCKET_NAME}
DYNAMODB_TABLE_NAME = ${TF_PROD_DYNAMODB_TABLE_NAME}
REGION = ${TF_PROD_REGION}
ROLE_NAME = ${TF_PROD_IAM_ROLE_NAME}
ROLE_DOC = '$(shell echo $${TF_PROD_IAM_ROLE_DOC})'
POLICY_NAME = ${TF_PROD_IAM_POLICY_NAME}
POLICY_DOC = '$(shell echo $${TF_PROD_IAM_POLICY_DOC})'
endif

.PHONY: profile s3 dynamodb update_backend update_provider staging production destroy_staging_backend destroy_prod_backend

profile:
# Create an AWS profile. You need an AWS Access Key ID and Secret Access Key to create a profile.
	aws configure --profile ${PROFILE_NAME}

role:
# Create an IAM role
# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/iam/create-role.html
	aws iam create-role \
		--role-name ${ROLE_NAME} \
		--assume-role-policy-document ${ROLE_DOC} \
		--profile ${PROFILE_NAME}

# Attach an inline policy to a role
# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/iam/put-role-policy.html
	aws iam put-role-policy \
		--role-name ${ROLE_NAME} \
		--policy-name ${POLICY_NAME} \
		--policy-document ${POLICY_DOC} \
		--profile ${PROFILE_NAME}

s3:
# Create S3 bucket
# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3api/create-bucket.html
	aws s3api create-bucket \
		--acl private \
		--bucket ${BUCKET_NAME} \
		--region ${REGION} \
		--create-bucket-configuration LocationConstraint=${REGION} \
		--profile ${PROFILE_NAME}
# Enable Versioning
# https://docs.aws.amazon.com/AmazonS3/latest/userguide/manage-versioning-examples.html
# You may want to enable MFA too: https://docs.aws.amazon.com/AmazonS3/latest/userguide/MultiFactorAuthenticationDelete.html
	aws s3api put-bucket-versioning \
		--bucket ${BUCKET_NAME} \
		--versioning-configuration Status=Enabled \
		--profile ${PROFILE_NAME}
# Disable public access
# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3api/put-public-access-block.html
	aws s3api put-public-access-block \
    	--bucket ${BUCKET_NAME} \
    	--public-access-block-configuration \
		"BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
		--profile ${PROFILE_NAME}

dynamodb:
# Create DynamoDB table
# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/dynamodb/create-table.html
	aws dynamodb create-table \
		--table-name ${DYNAMODB_TABLE_NAME} \
		--region ${REGION} \
		--attribute-definitions AttributeName=LockID,AttributeType=S \
		--key-schema AttributeName=LockID,KeyType=HASH \
		--provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
		--profile ${PROFILE_NAME}

update_backend:
	sed 's/{TERRAFORM_BACKEND_BUCKET_NAME}/${BUCKET_NAME}/g' terraform/$(MAKECMDGOALS)/backend.tf.template > terraform/$(MAKECMDGOALS)/backend.tf
	sed -i 's/{TERRAFORM_BACKEND_REGION}/${REGION}/g' terraform/$(MAKECMDGOALS)/backend.tf
	sed -i 's/{TERRAFORM_BACKEND_DYNAMODB_TABLE_NAME}/${DYNAMODB_TABLE_NAME}/g' terraform/$(MAKECMDGOALS)/backend.tf
	sed -i 's/{TERRAFORM_BACKEND_PROFILE_NAME}/${PROFILE_NAME}/g' terraform/$(MAKECMDGOALS)/backend.tf

destroy_staging_backend:
	VERSIONS=$$(aws s3api list-object-versions --bucket ${TF_STAGING_BUCKET_NAME} --query='Versions[].{Key:Key,VersionId:VersionId}' --output text --profile ${TF_STAGING_PROFILE_NAME}) ; \
	if [ "$${VERSIONS}" != "None" ]; then \
			aws s3api delete-objects --bucket ${TF_STAGING_BUCKET_NAME} --delete "$$(aws s3api list-object-versions --bucket ${TF_STAGING_BUCKET_NAME} --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --profile ${TF_STAGING_PROFILE_NAME})" ; \
	fi
	DELETE_MARKERS=$$(aws s3api list-object-versions --bucket ${TF_STAGING_BUCKET_NAME} --query='DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output text --profile ${TF_STAGING_PROFILE_NAME}) ; \
	if [ "$${DELETE_MARKERS}" != "None" ]; then \
			aws s3api delete-objects --bucket ${TF_STAGING_BUCKET_NAME} --delete "$$(aws s3api list-object-versions --bucket ${TF_STAGING_BUCKET_NAME} --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --profile ${TF_STAGING_PROFILE_NAME})" ; \
	fi
	aws s3 rb s3://${TF_STAGING_BUCKET_NAME} --force --profile ${TF_STAGING_PROFILE_NAME}
	aws dynamodb delete-table --table-name ${TF_STAGING_DYNAMODB_TABLE_NAME} --profile ${TF_STAGING_PROFILE_NAME}

destroy_prod_backend:
	VERSIONS=$$(aws s3api list-object-versions --bucket ${TF_PROD_BUCKET_NAME} --query='Versions[].{Key:Key,VersionId:VersionId}' --output text --profile ${TF_PROD_PROFILE_NAME}) ; \
	if [ "$${VERSIONS}" != "None" ]; then \
			aws s3api delete-objects --bucket ${TF_PROD_BUCKET_NAME} --delete "$$(aws s3api list-object-versions --bucket ${TF_PROD_BUCKET_NAME} --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --profile ${TF_PROD_PROFILE_NAME})" ; \
	fi
	DELETE_MARKERS=$$(aws s3api list-object-versions --bucket ${TF_PROD_BUCKET_NAME} --query='DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output text --profile ${TF_PROD_PROFILE_NAME}) ; \
	if [ "$${DELETE_MARKERS}" != "None" ]; then \
			aws s3api delete-objects --bucket ${TF_PROD_BUCKET_NAME} --delete "$$(aws s3api list-object-versions --bucket ${TF_PROD_BUCKET_NAME} --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --profile ${TF_PROD_PROFILE_NAME})" ; \
	fi
	aws s3 rb s3://${TF_PROD_BUCKET_NAME} --force --profile ${TF_PROD_PROFILE_NAME}
	aws dynamodb delete-table --table-name ${TF_PROD_DYNAMODB_TABLE_NAME} --profile ${TF_PROD_PROFILE_NAME}

update_provider:
	ROLE_ARN=$(shell aws iam get-role --role-name ${ROLE_NAME} --profile ${PROFILE_NAME} --query "Role.Arn" --output text) && \
	sed "s|{TERRAFORM_ROLE_ARN}|$$ROLE_ARN|g" terraform/$(MAKECMDGOALS)/providers.tf.template > terraform/$(MAKECMDGOALS)/providers.tf

staging production: update_backend profile role update_provider s3 dynamodb

# Local Terraform Recipes
.PHONY: format format-mods format-stag format-prod plan-stag apply-stag dest-stag plan-prod apply-prod dest-prod

format-mods:
	@for dir in terraform/modules/*/; do \
    	cd $$dir; \
		echo "currently at $$dir"; \
		terraform fmt; \
		cd -; \
	done

format-stag:
	@cd terraform/staging/; terraform fmt

format-prod:
	@cd terraform/production/; terraform fmt

format:
	make format-mods
	make format-stag
	make format-prod 

plan-stag: format
	cd terraform/staging; terraform init; terraform validate; \
	terraform plan \
		-var-file="terraform.tfvars" \
        -input=false \
		-out=tfplan

apply-stag: plan-stag
	cd terraform/staging; terraform apply \
    	-input=false \
		tfplan

dest-stag:
	cd terraform/staging; terraform destroy \
		-var-file="terraform.tfvars" 

plan-prod: format
	cd terraform/production; terraform init; terraform validate; \
	terraform plan \
		-var-file="terraform.tfvars" \
        -input=false \
		-out=tfplan

apply-prod: plan-prod
	cd terraform/production; terraform apply \
    	-input=false \
		tfplan

dest-prod:
	cd terraform/production; terraform destroy \
		-var-file="terraform.tfvars" 
