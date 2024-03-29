# force:package:create only execute for the first time
# sfdx force:package:create -n ApexTriggerHandler -t Unlocked -r apex-trigger-handler
sfdx force:package:version:create -p ApexTriggerHandler -x -c --wait 10 --codecoverage
sfdx force:package:version:list
sfdx force:package:version:promote -p 04t2v000007CfgQAAS
sfdx force:package:version:report -p 04t2v000007CfgQAAS


# sfdx force:package:create -n ApexTriggerHandlerExt -t Unlocked -r apex-trigger-loader
sfdx force:package:version:create -p ApexTriggerHandlerExt -x -c --wait 10 --codecoverage
sfdx force:package:version:list
sfdx force:package:version:promote -p 04t2v000007CfgVAAS
sfdx force:package:version:report -p 04t2v000007CfgVAAS