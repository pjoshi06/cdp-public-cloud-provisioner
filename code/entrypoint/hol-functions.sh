#!/bin/bash
# *************************************************************************************************************#
# Setting required path and variables.
USER_CONFIG_FILE="/userconfig/configfile"
KC_TF_CONFIG_DIR=$HOME_DIR/cdp-wrkshps-quickstarts/cdp-kc-config/keycloak_terraform_config
KC_ANS_CONFIG_DIR=$HOME_DIR/cdp-wrkshps-quickstarts/cdp-kc-config/keycloak_ansible_config
CDP_TF_CONFIG_DIR=$HOME_DIR/cdp-wrkshps-quickstarts/cdp-env-tf
DS_CONFIG_DIR=$HOME_DIR/cdp-wrkshps-quickstarts/cdp-data-services
USER_ACTION=$1
validating_variables () {
echo
echo "                                             ---------------------------------------                     "
echo "                                             Verifying The Provided Input Parameters                     "
echo "                                             ---------------------------------------                     "
echo
sleep 10
if [ ! -f "/userconfig/configfile" ]
then
echo "=================================================================================="
echo "FATAL: Not able to find Config File ('configfile') inside /userconfig folder.
Please make sure you have mounted the local directory using -v flag and you
have created a file by name 'configfile' without any file extension like '.txt'.
if you are running docker on windows then create the folder inside your
'C:/Users/<Your_Windows_User_Name>/' and try again.
Exiting......"
echo "=================================================================================="
exit 9999 # die with error code 9999

fi
# Cleaning up 'configfile' to remove ^M characters.
sed -i 's/^M//g' $USER_CONFIG_FILE
# Read variables from the text file

            while IFS=':' read -r key value; do
            if [[ -z "$value" && $key != "#"* ]]; then
               echo "========================================================================================="
               echo "FATAL: $key Can Not Have Null Value. Please update the 'configfile' and try again.
EXITING......               "
               echo "========================================================================================="
               exit 1
            fi
            if [[ $key && $value  ]]; then
            key=$(echo "$key" | tr -d '[:space:]')  # Remove whitespace from the key
            value=$(echo "$value" | tr -d '[:space:]')  # Remove whitespace from the value
           # Processing each variable
           case $key in
              KEYCLOAK_SERVER_NAME)
                ec2_instance_name=$value
                 ;;
              AWS_ACCESS_KEY_ID)
               aws_access_key_id=$value
                ;;
              AWS_SECRET_ACCESS_KEY)
               aws_secret_access_key=$value
               ;;
              AWS_REGION)
               aws_region=$value
               ;;
              WORKSHOP_NAME)
                 case $value in
                 *_*)
                    echo "=================================================================================="                 
                    echo "FATAL: The value for Workshop Name parameter  can not have underscore ('_').
Please update the value in 'configfile' and try again."
                    echo "=================================================================================="                    
                    exit 1
                    ;;
                  *)    
                  workshop_name=$(echo "$value" | tr '[:upper:]' '[:lower:'])
                  ;;
                  esac      
               ;;
              NUMBER_OF_WORKSHOP_USERS)
               number_of_workshop_users=$value
               ;;
              WORKSHOP_USER_PREFIX)
               workshop_user_prefix=$(echo "$value" | tr '[:upper:]' '[:lower:'])
               ;;
              WORKSHOP_USER_DEFAULT_PASSWORD)
               workshop_user_default_password=$value
               ;; 
              CDP_ACCESS_KEY_ID)
               cdp_access_key_id=$value
               ;;
              CDP_PRIVATE_KEY)
               cdp_private_key=$value
               ;;
              AWS_KEY_PAIR)
               aws_key_pair=$value
               echo $aws_key_pair
               ;;
              CDP_DEPLOYMENT_TYPE)
               if [[ "$value" == "public" || "$value" == "private" || "$value" == "semi-private" ]]; then
                deployment_template=$value
               else
                echo "=================================================================================="               
                echo "FATAL: Invalid value for CDP Deployment Type. The allowed values are: 
public (* all in lowercase *)
private (* all in lowercase *)
semi-private (* all in lowercase and one hyphen (-) *)

****Exiting****
Please update the 'configfile' and try again."
                echo "=================================================================================="
                exit 9999
               fi 
               ;;
              LOCAL_MACHINE_IP)
               local_ip=$value
               ;;
              KEYCLOAK_SECURITY_GROUP_NAME)
               keycloak_sg_name=$value
               ;;
              ENABLE_DATA_SERVICES)
               enable_data_services=$value
               ;;   
                          
              # Can Add more cases if required.
            esac
          fi
        done < "$USER_CONFIG_FILE"

echo
echo "                                             ---------------------------------------                     "
echo "                                             Verified The Provided Input Parameters                      "
echo "                                             ---------------------------------------                     "
echo
}
#--------------------------------------------------------------------------------------------------------------#
# Function for checking .pem file.
key_pair_file () {
   # Checking if SSH Keypair File exists.
if [[ ! -f "/userconfig/$aws_key_pair.pem" ]]; then
echo "=================================================================================="                 
echo "FATAL: SSH Key Pair File Not Found. Please place the '$aws_key_pair.pem' 
file in your config directory and try again.
EXITING....."
echo "=================================================================================="
exit 9999 # die with error code 9999
fi
}
#-------------------------------------------------------------------------------------------------#
# Function to setup AWS & CDP CLI for user.
setup_aws_and_cdp_profile () {
echo "                       =================================================================================="
echo "                                         Setting Up Your AWS & CDP Profile                               "
echo "                       =================================================================================="
aws configure set aws_access_key_id $aws_access_key_id; \
aws configure set aws_secret_access_key $aws_secret_access_key; \
aws configure set default.region $aws_region
cdp configure set cdp_access_key_id $cdp_access_key_id; \
cdp configure set cdp_private_key $cdp_private_key;
}
#---------------------------------------------------------------------------------------------------------------------#
# Function to verify AWS pre-requisites
aws_prereq () {
   
          vpc_limit=$(aws service-quotas get-service-quota \
          --service-code vpc \
          --output json \
          --region $aws_region \
          --quota-code L-F678F1CE | jq -r '.[]["Value"]')

          vpc_used=$(aws ec2 describe-vpcs --output json --region $aws_region | jq -r '.[] | length')

               if [ $vpc_limit -gt $vpc_used ]; then
                    echo "Check Available VPC .....Passed"
               else
                    echo
                    echo "************************************************************************************************************************************************************"
                    echo "* Fatal !! Can't Continue: The VPC limit has been reached in the $aws_region region. Either select any other region in 'configfile' or remove unused VPC's *"
                    echo "************************************************************************************************************************************************************"
                    exit
               fi
         eip_limit=$(aws service-quotas get-service-quota \
          --service-code ec2 \
          --output json \
          --region $aws_region \
          --quota-code L-0263D0A3 | jq -r '.[]["Value"]')
         eip_used=$(aws ec2 describe-addresses --output json --region $aws_region | jq -r '.[] | length')
              
              if [[ $(( $eip_limit - $eip_used )) -ge 5 ]]; then
                    echo "Check Available EIP ....Passed"
              else
                    echo
                    echo "*************************************************************************************************************************************************************************************************"
                    echo "* Fatal !! Can't Continue: There are not enough free Elastic IP's available in the $aws_region region. Either select any other region in 'configfile' or release unused EIPs in $aws_region     *"
                    echo "*************************************************************************************************************************************************************************************************"
                    exit
               fi      
   
}
#---------------------------------------------------------------------------------------------------------------------#
# Function to validate if resources are already present on AWS.
check_aws_sg_exists() {
sg_name="$1"
# Checking if Security Group exists.
local sg_group_info=$(aws ec2 describe-security-groups --filters "Name=group-name,Values='$sg_name'" --output text 2>/dev/null)
# Validating the output
if [[ -n $sg_group_info ]]; then
   return 0
else
   return 1
fi      
}
#-------------------------------------------------------------------------------------------------#
# Function to provision EC2 Instance for Keycloak
setup_keycloak_ec2 () {
echo "==============================Provisioning Keycloak========================================="
USER_NAMESPACE=$workshop_name
mkdir -p /userconfig/.$USER_NAMESPACE
cp -R $KC_TF_CONFIG_DIR /userconfig/.$USER_NAMESPACE/
cp -R $KC_ANS_CONFIG_DIR /userconfig/.$USER_NAMESPACE/
cd /userconfig/.$USER_NAMESPACE/keycloak_terraform_config
local sg_name="$1"
if check_aws_sg_exists "$sg_name"; then
   echo "EC2 Security Group With the same name already exists. To avoid the failure the Security Group
name is now updated to $keycloak_sg_name-$workshop_name-sg"
terraform init
terraform apply -auto-approve \
          -var "instance_name=$ec2_instance_name" \
          -var "local_ip=$local_ip" \
          -var "instance_keypair=$aws_key_pair" \
          -var "aws_region=$aws_region" \
          -var "kc_security_group=$sg_name-$workshop_name-sg"
RETURN=$?
           if [ $RETURN -eq 0 ]; then        
                KEYCLOAK_SERVER_IP=$(terraform output -raw elastic_ip)
                echo $KEYCLOAK_SERVER_IP > /userconfig/keycloak_ip
               return 0
            else
               return 1
            fi
else
terraform init
terraform apply -auto-approve \
          -var "instance_name=$ec2_instance_name" \
          -var "local_ip=$local_ip" \
          -var "instance_keypair=$aws_key_pair" \
          -var "aws_region=$aws_region" \
          -var "kc_security_group=$sg_name"
RETURN=$?
           if [ $RETURN -eq 0 ]; then        
                KEYCLOAK_SERVER_IP=$(terraform output -raw elastic_ip)
                echo $KEYCLOAK_SERVER_IP > /userconfig/keycloak_ip
               return 0
            else
               return 1
            fi         
fi          
 }
#--------------------------------------------------------------------------------------------------#
# Function to rollback keycloack EC2 Instance in case of failure during provision.
destroy_keycloak () {
USER_NAMESPACE=$workshop_name
echo "===================================Destroying Keycloak======================================="
cd /userconfig/.$USER_NAMESPACE/keycloak_terraform_config
terraform init
terraform destroy -auto-approve \
          -var "instance_name=$ec2_instance_name" \
          -var "local_ip=$local_ip" \
          -var "instance_keypair=$aws_key_pair" \
          -var "aws_region=$aws_region" \
          -var "kc_security_group=$sg_name"

rm -rf /userconfig/.$USER_NAMESPACE/keycloak_terraform_config
rm -rf /userconfig/.$USER_NAMESPACE/keycloak_ansible_config
rm -rf /userconfig/keycloak_ip
}
#--------------------------------------------------------------------------------------------------#
# Function to provision CDP Environment.
provision_cdp () {
echo "==============================Provisioning CDP Environment==================================="
sleep 10
USER_NAMESPACE=$workshop_name
cp -R $CDP_TF_CONFIG_DIR /userconfig/.$USER_NAMESPACE/
cd /userconfig/.$USER_NAMESPACE/cdp-env-tf/aws
cdp_cidr="\"$local_ip\""
terraform init
terraform apply --auto-approve \
        -var "env_prefix=${workshop_name}" \
        -var "aws_region=${aws_region}" \
        -var "aws_key_pair=${aws_key_pair}" \
        -var "deployment_template=${deployment_template}" \
        -var "ingress_extra_cidrs_and_ports={cidrs = ["${cdp_cidr}"],ports = [443, 22]}"
cdp_provision_status=$?
if [ $cdp_provision_status -eq 0 ]; then
               export ENV_PUBLIC_SUBNETS=$(terraform output -json aws_public_subnet_ids)
               export ENV_PRIVATE_SUBNETS=$(terraform output -json aws_private_subnet_ids)
               return 0
            else
               return 1
            fi

}
#--------------------------------------------------------------------------------------------------#
# Update the User Group.
update_cdp_user_group() {
   cdp iam update-group --group-name $workshop_name-cdp-user-group --sync-membership-on-user-login
}
#--------------------------------------------------------------------------------------------------#
# Function to destroy CDP Environment.
destroy_cdp () {
USER_NAMESPACE=$workshop_name
echo "==============================Destroying CDP Environment Infrastructure========================================"
cd /userconfig/.$USER_NAMESPACE/cdp-env-tf/aws
cdp_cidr="\"$local_ip\""
terraform init
terraform destroy --auto-approve \
         -var "env_prefix=${workshop_name}" \
         -var "aws_region=${aws_region}" \
         -var "aws_key_pair=${aws_key_pair}" \
         -var "deployment_template=${deployment_template}" \
         -var "ingress_extra_cidrs_and_ports={cidrs = ["${cdp_cidr}"],ports = [443, 22]}"
rm -rf /userconfig/.$USER_NAMESPACE/cdp-env-tf       
}
#--------------------------------------------------------------------------------------------------#
# Function to destroy Complete HOL Infrastructure.
destroy_hol_infra () {
   destroy_cdp
   destroy_keycloak
   rm -rf /userconfig/.$USER_NAMESPACE
   rm -rf /userconfig/$workshop_name.txt
}
#--------------------------------------------------------------------------------------------------#
# Function to configure IDP Client
cdp_idp_setup_user () {
KEYCLOAK_SERVER_IP=$(cat /userconfig/keycloak_ip)
USER_NAMESPACE=$workshop_name
cd /userconfig/.$USER_NAMESPACE/keycloak_ansible_config
echo "=========================Configuring IDP in CDP=============================================="
sleep 5
ansible-playbook create_keycloak_client.yml --extra-vars \
         "keycloak__admin_username=admin \
          keycloak__admin_password=Cloudera123 \
          keycloak__domain=http://$KEYCLOAK_SERVER_IP/ \
          keycloak__cdp_idp_name=$workshop_name \
          keycloak__realm=master \
          keycloak__auth_realm=master"
echo "=========================Creating Users & Groups=============================================="
sleep 5
ansible-playbook keycloak_hol_user_setup.yml --extra-vars \
   "keycloak__admin_username=admin \
    keycloak__admin_password=Cloudera123 \
    keycloak__domain=http://$KEYCLOAK_SERVER_IP \
    hol_keycloak_realm=master \
    hol_session_name=$workshop_name-cdp-user-group \
    number_user_to_create=$number_of_workshop_users \
    username_prefix=$workshop_user_prefix \
    default_user_password=$workshop_user_default_password \
    reset_password_on_first_login=True"
sleep 10
echo "==========================Synchronising Keycloak Users In CDP=================================="
for i in $(seq -f "%02g" 1 1 $number_of_workshop_users); do
cdp iam create-user \
--identity-provider-user-id $workshop_user_prefix$i \
--email $workshop_user_prefix$i@clouderaexample.com \
--saml-provider-name $workshop_name \
--groups "$workshop_name-cdp-user-group" \
--first-name User-$workshop_user_prefix$i \
--last-name $workshop_user_prefix$i;
done
cdp environments sync-all-users --environment-names $workshop_name-cdp-env
sleep 5
echo "==========================Please Wait: Generating Report======================================="
cd /userconfig/.$USER_NAMESPACE/keycloak_ansible_config
ansible-playbook keycloak_hol_user_fetch.yml --extra-vars \
   "keycloak__admin_username=admin \
    keycloak__admin_password=Cloudera123 \
    keycloak__domain=http://$KEYCLOAK_SERVER_IP \
    hol_keycloak_realm=master \
    hol_session_name=$workshop_name-cdp-user-group"
sleep 5
echo "=============================Fetching Details: Please Wait=========================="
sample_keycloak_user1=$(cat /tmp/$workshop_name-cdp-user-group.json | jq -r '.[0].username')
sample_keycloak_user2=$(cat /tmp/$workshop_name-cdp-user-group.json | jq -r '.[1].username')
sleep 5
echo "===============================================================" >> "/userconfig/$workshop_name.txt"
echo "            Keycloak Details For $workshop_name HOL:           " >> "/userconfig/$workshop_name.txt"
echo "===============================================================" >> "/userconfig/$workshop_name.txt"
echo "Keycloak Server IP: $KEYCLOAK_SERVER_IP" >> "/userconfig/$workshop_name.txt"
echo "Keycloak Admin URL: http://$KEYCLOAK_SERVER_IP" >> "/userconfig/$workshop_name.txt"
echo "Keycloak Admin User: admin" >> "/userconfig/$workshop_name.txt"
echo "Keycloak Admin Password: Cloudera123" >> "/userconfig/$workshop_name.txt"
echo "Keycloak SSO URL: http://$KEYCLOAK_SERVER_IP/realms/master/protocol/saml/clients/cdp-sso" >> "/userconfig/$workshop_name.txt"
echo "Numbers Of Users Created: $number_of_workshop_users" >> "/userconfig/$workshop_name.txt"
echo "Sample Usernames: User1:$sample_keycloak_user1, User2:$sample_keycloak_user2" >> "/userconfig/$workshop_name.txt"
echo "Default Password for HOL Users: $workshop_user_default_password " >> "/userconfig/$workshop_name.txt"
echo "===============================================================" >> "/userconfig/$workshop_name.txt"
}
#--------------------------------------------------------------------------------------------------#
cdp_idp_user_teardown () {
USER_NAMESPACE=$workshop_name
echo "====================Deleting IDP Users & Group==============================================="
KEYCLOAK_SERVER_IP=$(cat /userconfig/keycloak_ip)
echo $KEYCLOAK_SERVER_IP
cd /userconfig/.$USER_NAMESPACE/keycloak_ansible_config
ansible-playbook keycloak_hol_user_teardown.yml --extra-vars \
   "keycloak__admin_username=admin \
    keycloak__admin_password=Cloudera123 \
    keycloak__domain=http://$KEYCLOAK_SERVER_IP \
    hol_keycloak_realm=master \
    hol_session_name=$workshop_name-cdp-user-group"
sleep 10
echo "====================Removing IDP From CDP Tenant============================================="
cdp iam delete-saml-provider --saml-provider-name $workshop_name
}
#--------------------------------------------------------------------------------------------------#
deploy_cdw () {
echo "==========================Deploying CDW======================================"
number_vw_to_create=$(( ($number_of_workshop_users / 10) + ($number_of_workshop_users % 10 > 0) ))
ansible-playbook $DS_CONFIG_DIR/enable-cdw.yml --extra-vars \
"cdp_env_name=$workshop_name-cdp-env \
env_public_subnet=$ENV_PUBLIC_SUBNETS \
env_private_subnet=$ENV_PRIVATE_SUBNETS \
workshop_name=$workshop_name \
number_vw_to_create=$number_vw_to_create"
}
#--------------------------------------------------------------------------------------------------#
disable_cdw () {
   echo "==========================Disabling CDW======================================"
   ansible-playbook $DS_CONFIG_DIR/disable-cdw.yml --extra-vars \
   "cdp_env_name=$workshop_name-cdp-env"
}
#--------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------#
deploy_cde () {
echo "==========================Deploying CDE======================================"
number_vc_to_create=$(( ($number_of_workshop_users / 10) + ($number_of_workshop_users % 10 > 0) ))
ansible-playbook $DS_CONFIG_DIR/enable-cde.yml --extra-vars \
"cdp_env_name=$workshop_name-cdp-env \
workshop_name=$workshop_name \
number_vc_to_create=$number_vc_to_create"

}
#--------------------------------------------------------------------------------------------------#
disable_cde () {
   echo "==========================Disabling CDE======================================"
   ansible-playbook $DS_CONFIG_DIR/disable-cde.yml --extra-vars \
   "workshop_name=$workshop_name"
}
#--------------------------------------------------------------------------------------------------#
enable_data_services () {
   # Remove the brackets.
   enable_data_services="${enable_data_services//[}"
   enable_data_services="${enable_data_services//]}"
   # converting to lower case.
   enable_data_services=$(echo "$enable_data_services" | tr '[:upper:]' '[:lower:]')
   # Spliting into array.
   IFS=',' read -ra data_services <<< "$enable_data_services"

   # Deploying selected data services
   for service in "${data_services[@]}"; do
       if [[ "$service" == "cdw" ]]; then
         deploy_cdw
      elif [[ "$service" == "cde" ]]; then
          deploy_cde
      elif [[ "$service" == "cdf" ]]; then
          echo "CDF"
      else
          echo "No Data Services Selected"
      fi
   done              
            
}
#--------------------------------------------------------------------------------------------------#
disable_data_services () {
   # Remove the brackets.
   enabled_data_services="${enable_data_services//[}"
   enabled_data_services="${enabled_data_services//]}"
   # converting to lower case.
   enabled_data_services=$(echo "$enabled_data_services" | tr '[:upper:]' '[:lower:]')
   # Spliting into array.
   IFS=',' read -ra data_services <<< "$enabled_data_services"

   # Deploying selected data services
   for service in "${data_services[@]}"; do
       if [[ "$service" == "cdw" ]]; then
         disable_cdw
      elif [[ "$service" == "cde" ]]; then
          disable_cde
      elif [[ "$service" == "cdf" ]]; then
          echo "CDF"
      else
          echo "No Data Services were deployed"
      fi
   done              
            
}
#--------------------------------------------------------------------------------------------------#