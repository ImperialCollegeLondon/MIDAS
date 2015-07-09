#!/bin/sh

export PERL5LIB=../../../perl5/lib/perl5:../../Bio-Metadata-Validator/lib:../../Bio-HICF-Schema/lib
export CATALYST_CONFIG=midas.conf
export CATALYST_CONFIG_LOCAL_SUFFIX=testing
export CATALYST_DEBUG=1
export DBIC_TRACE=1

# sqlite3 testing.db < t/data/create_full_test_db.sql
cp t/data/data.db temp_data.db
cp t/data/user.db temp_user.db

perl script/midas_server.pl --port 3001

