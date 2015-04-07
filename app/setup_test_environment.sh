# source to set up a shell for running tests, something like
#
#   bash% source setup_dev_environment.sh
#   bash% prove -vl t
#   t/01app.t ..............
#   ok 1 - Request should succeed
#   ...
#
# jt6 20150407 WTSI

export PERL5LIB=../../Bio-Metadata-Validator/lib:../../Bio-HICF-Schema/lib:$PERL5LIB
export CATALYST_CONFIG=midas.conf
export CATALYST_CONFIG_LOCAL_SUFFIX=testing
export CATALYST_DEBUG=0
export DBIC_TRACE=0
