password for the keystore.jceks is in .storepass file


tomcat cert:
  keytool    -keystore tomcatcert.jceks    -alias server-cert    -storetype JCEKS   -genkeypair   -keyalg RSA   -keysize 2048   -validity 10065    -dname "CN=fr-am.local, OU=amido, O=amido, L=London S=London C=UK"
  passsword: Pa55word11

  The JCEKS keystore uses a proprietary format. It is recommended to migrate to PKCS12 which is an industry standard format using "keytool -importkeystore -srckeystore tomcatcert.jceks -destkeystore tomcatcert.jceks -deststoretype pkcs12"


