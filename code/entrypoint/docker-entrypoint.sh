#!/bin/bash
# ***************************************************************************************************#
source /usr/local/bin/hol-functions.sh
# Setting required path and variables.
USER_CONFIG_FILE="/userconfig/configfile"
TERRAFORM_DIR=$HOME_DIR/cdp-wrkshps-quickstarts/cdp-kc-config/keycloak_terraform_config
DS_CONFIG_DIR=$HOME_DIR/cdp-wrkshps-quickstarts/cdp-data-services
USER_ACTION=$1
# Handling the User Action ('provision' or 'destroy').
case $USER_ACTION in
   provision)
          validating_variables
          key_pair_file
          setup_aws_and_cdp_profile
          aws_prereq
          setup_keycloak_ec2 $keycloak_sg_name
          if [ $? -ne 0 ]; then
             echo "Keycloak Server Provisioning Failed. Rolling Back The Changes."
             destroy_keycloak
             echo "Infrastructure Provisioning For $workshop_name Is Not Succesful.
Please Try Again. Exiting....."
             exit 1
          else
             echo "================Keycloak Server Provisioned=============================="
             echo
          fi
          sleep 10
          provision_cdp
          if [ $? -ne 0 ]; then
             echo "CDP Environment Provisioning Failed. Rolling Back The Changes."
             destroy_cdp
             destroy_keycloak
             echo "Infrastructure Provisioning For $workshop_name Is Not Succesful.
Please Try Again. Exiting....."
             exit 1
          else
             echo "================CDP Environment Provisioned=============================="
             echo
           fi
           update_cdp_user_group
           cdp_idp_setup_user
           enable_data_services
           echo "===================Infrastructure Provisioned==============================" 
           
         ;;
   destroy)
          validating_variables
          setup_aws_and_cdp_profile
          cdp_idp_user_teardown
          disable_data_services
          destroy_hol_infra
          ;;
   *) 
         echo "Inavlid Input. Valid values are 'provision' or 'destroy'"      
         ;;

esac
# ***********************************************************************************************#