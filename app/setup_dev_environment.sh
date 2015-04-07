# source to set up a shell for running the dev server, something like
#
#   bash% source setup_dev_environment.sh
#   bash% perl script/midas_server.pl
#   [debug] Debug messages enabled
#   [debug] Statistics enabled
#   [debug] Loaded Config "midas.conf"
#   [debug] Setting up auth realm db
#   ...
#
# jt6 20150407 WTSI

export PERL5LIB=../../Bio-Metadata-Validator/lib:../../Bio-HICF-Schema/lib:$PERL5LIB
export CATALYST_CONFIG=midas.conf
export CATALYST_CONFIG_LOCAL_SUFFIX=local
export CATALYST_DEBUG=1
export DBIC_TRACE=1
