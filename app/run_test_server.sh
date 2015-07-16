#!/bin/sh

export PERL5LIB=../../../perl5/lib/perl5:../../Bio-Metadata-Validator/lib:../../Bio-HICF-Schema/lib
export CATALYST_CONFIG=midas.conf
export CATALYST_CONFIG_LOCAL_SUFFIX=testing
export CATALYST_DEBUG=$CATALYST_DEBUG || 1
export DBIC_TRACE=$DBIC_TRACE || 1

# this is a SQLite DB that has multiple rows in the sample table, specifically for use
# with the front-end tests
cp t/data/multiple_samples.db temp_data.db
cp t/data/user.db temp_user.db

perl script/midas_server.pl --port 3001

