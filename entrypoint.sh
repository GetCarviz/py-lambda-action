#!/bin/bash
set -e

install_zip_dependencies(){
	echo "Installing and zipping dependencies..."
	mkdir python
	pip install --target=python -r "${INPUT_REQUIREMENTS_TXT}"
	zip -r dependencies.zip ./python
}

publish_dependencies_as_layer(){
	echo "Publishing dependencies as a layer..."
 	local result
	result=$(aws lambda publish-layer-version --layer-name "${INPUT_LAMBDA_LAYER_ARN}" --zip-file fileb://dependencies.zip --compatible-runtimes "python${INPUT_PYTHON_VERSION}" --compatible-architectures "x86_64")
	LAYER_VERSION=$(jq '.Version' <<< "$result")
	rm -rf python
	rm dependencies.zip
}

publish_function_code(){
	echo "Deploying the code itself..."
	zip -r code.zip . -x \*.git\*
	aws lambda update-function-code --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --zip-file fileb://code.zip
}

update_function_layers(){
	echo "Using the layer in the function..."
 	local function_state
  	local function_status
	function_state=$(aws lambda get-function --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --query 'Configuration.State')
 	function_status=$(aws lambda get-function --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --query 'Configuration.LastUpdateStatus')
	while [[ $function_state != "\"Active\"" && $function_status != "\"Successful\"" ]]
 	do
		function_state=$(aws lambda get-function --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --query 'Configuration.State')
  		function_status=$(aws lambda get-function --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --query 'Configuration.LastUpdateStatus')
		sleep 1
	done
 	echo "The Function State is: $function_state"
 	echo "The Function Status is: $function_status"

 	# Prepare the new layer ARN
 	local new_layer="${INPUT_LAMBDA_LAYER_ARN}:${LAYER_VERSION}"

 	# Convert the comma-separated list of addon layers into an array
 	IFS=',' read -r -a addon_layers_array <<< "$addon_layer_arns"

 	# Construct the complete list of layers, including the new layer
 	local layers_list=("$new_layer")
 	for addon_layer in "${addon_layers_array[@]}"; do
 	    layers_list+=("$addon_layer")
 	done

 	# Join the layers list into a comma-separated string
 	local layers=$(IFS=,; echo "${layers_list[*]}")

 	# Update the Lambda function with the new layers configuration
	aws lambda update-function-configuration --function-name "${INPUT_LAMBDA_FUNCTION_NAME}" --layers $layers
}

deploy_lambda_function(){
	install_zip_dependencies
	publish_dependencies_as_layer
	publish_function_code
	update_function_layers
}

deploy_lambda_function
echo "Done."
