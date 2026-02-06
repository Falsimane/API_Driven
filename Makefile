# --- CONFIGURATION ---
export ENDPOINT_URL := https://literate-space-guide-pq46pgj677937wp7-4566.app.github.dev
export AWS_ACCESS_KEY_ID := test
export AWS_SECRET_ACCESS_KEY := test
export AWS_DEFAULT_REGION := us-east-1
export AWS_REGION := us-east-1

AWS_CMD := aws --endpoint-url=$(ENDPOINT_URL)

.PHONY: all install deploy-lambda create-ec2 create-api 

all: install deploy-lambda create-ec2 create-api 

install: 
	@echo "--- Lancement du script d'installation ---"
	chmod +x setup_env.sh
	./setup_env.sh

deploy-lambda:
	@echo "--- Déploiement Lambda ---"
	zip function.zip lambda_function.py
	$(AWS_CMD) lambda create-function --function-name EC2Manager \
		--zip-file fileb://function.zip --handler lambda_function.lambda_handler \
		--runtime python3.9 --role arn:aws:iam::000000000000:role/Role \
		--environment Variables={ENDPOINT_URL=$(ENDPOINT_URL)} || \
	$(AWS_CMD) lambda update-function-code --function-name EC2Manager --zip-file fileb://function.zip

create-ec2: 
	@echo "--- 🖥️ Lancement d'une instance EC2 de test ---"
	$(eval INSTANCE_ID := $(shell $(AWS_CMD) ec2 run-instances --image-id ami-df5de72ade3b --count 1 --instance-type t2.micro --query 'Instances[0].InstanceId' --output text))
	@echo $(INSTANCE_ID) > instance_id.txt
	@echo "Instance créée : $(INSTANCE_ID)"

create-api:
	@echo "--- 🌐 Configuration de l'API Gateway ---"
	$(eval API_ID := $(shell $(AWS_CMD) apigateway create-rest-api --name 'EC2ControlAPI' --query 'id' --output text))
	$(eval PARENT_ID := $(shell $(AWS_CMD) apigateway get-resources --rest-api-id $(API_ID) --query 'items[0].id' --output text))
	$(eval RES_ID := $(shell $(AWS_CMD) apigateway create-resource --rest-api-id $(API_ID) --parent-id $(PARENT_ID) --path-part monitor --query 'id' --output text))
	$(AWS_CMD) apigateway put-method --rest-api-id $(API_ID) --resource-id $(RES_ID) --http-method GET --authorization-type "NONE"
	$(AWS_CMD) apigateway put-integration --rest-api-id $(API_ID) --resource-id $(RES_ID) --http-method GET \
		--type AWS_PROXY --integration-http-method POST \
		--uri arn:aws:apigateway:$(AWS_REGION):lambda:path/2015-03-31/functions/arn:aws:lambda:$(AWS_REGION):000000000000:function:EC2Manager/invocations
	$(AWS_CMD) apigateway create-deployment --rest-api-id $(API_ID) --stage-name prod
	@echo ""
	@echo "==========================================================="
	@echo "🚀 TEST DE L'API ICI :"
	@echo "$(ENDPOINT_URL)/restapis/$(API_ID)/prod/_user_request_/monitor?action=stop&instance_id=$$(cat instance_id.txt)"
	@echo "==========================================================="

clean:
	@echo "--- 🧹 Nettoyage ---"
	rm -f function.zip instance_id.txt
	$(AWS_CMD) lambda delete-function --function-name EC2Manager || true