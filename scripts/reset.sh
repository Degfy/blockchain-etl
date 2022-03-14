# ! /bin/sh
rm -rf /var/data/ledger.db
rm -rf /var/data/log/*
/opt/etl/bin/blockchain_etl migrations reset