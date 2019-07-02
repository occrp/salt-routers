#!/bin/sh
# edit rsax931.py for salt

router=$1

# In case there are no tmp files, it will create them
echo "TESTING!"
sudo salt-ssh $router test.ping

# TEMPORARY SOLUTION!!! Remove the code from rsax931.py to avoid OSError: Cannot locate OpenSSL libcrypto
echo "SOLVING OSError: Cannot locate OpenSSL libcrypto"
sudo salt-ssh $router -r "cd /var/tmp/.root*/py2/salt/utils/ && sed -i \"s/lib = find_library('crypto')/lib = 'libcrypto.so.1.0.0'/\" rsax931.py"

# Test if everything works
echo "TESTING!"
sudo salt-ssh $router test.ping
