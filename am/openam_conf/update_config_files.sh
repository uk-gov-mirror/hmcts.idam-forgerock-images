cd whatever/config_files

grep -rl forgerock-am-idam-sandbox000000.service.core-compute-idam-sandbox.internal . | xargs sed -i '' 's,forgerock-am-idam-sandbox000000.service.core-compute-idam-sandbox.internal,AMSTER{amHost},g'
grep -rl forgerock-am.service.core-compute-idam-sandbox.internal . | xargs sed -i '' 's,forgerock-am.service.core-compute-idam-sandbox.internal,AMSTER{amHost},g'
grep -rl forgerock-ds-tokenstore.service.core-compute-idam-sandbox.internal . | xargs sed -i '' 's,forgerock-ds-tokenstore.service.core-compute-idam-sandbox.internal,AMSTER{ctsHost},g'
grep -rl forgerock-ds-userstore.service.core-compute-idam-sandbox.internal . | xargs sed -i '' 's,forgerock-ds-userstore.service.core-compute-idam-sandbox.internal,AMSTER{cfgUserStoreHost},g'
grep -rl 8080 . | xargs sed -i '' 's,8080,AMSTER{amHostPort},g'
grep -rl 8443 . | xargs sed -i '' 's,8443,AMSTER{amHostPort},g'
grep -rl "ctsHost}:1636" . | xargs sed -i '' 's,ctsHost}:1636,ctsHost}:AMSTER{ldapCtsPort},g'
grep -rl "cfgUserStoreHost}:1639" . | xargs sed -i '' 's,cfgUserStoreHost}:1639,cfgUserStoreHost}:AMSTER{ldapcfgUserStorePort},g'
grep -rl "https:" . | xargs sed -i '' 's,https:,AMSTER{amHttpProtocol},g'
grep -rl LDAPS . | xargs sed -i '' 's,LDAPS,AMSTER{ldapProtocol},g'
grep -rl \"AMSTER{pwdEncKey}\" . | xargs sed -i '' 's,\"AMSTER{pwdEncKey}\",null,g'

#we don't need all the files like authSocialVk.json authJwtPoP.json etc.
find . -name auth*.json -exec rm {} +

# we don't nee sites now...
rm -rf global/Sites/
