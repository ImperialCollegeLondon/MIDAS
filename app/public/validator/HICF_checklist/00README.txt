
Validating a sample manifest
============================

This document explains how to use the "validate_manifest" perl script to check
the contents of a sample manifest before deposition with the HICF sample data
repository.

Install the perl module and script
----------------------------------

The usual way to do this is something like this:

  shell% tar zxf Bio-Metadata-Validator-1.150070.tar.gz
  shell% cd Bio-Metadata-Validator-1.150070
  shell% perl Makefile.PL
  ...
  shell% make install
  ...

However, the script has quite a number of dependencies, so it may be easier to
use cpanm (see https://github.com/miyagawa/cpanminus) to install the tarball
directly. 'cpanm' will detect and install the pre-requisites automatically:

  shell% cpanm Bio-Metadata-Validator-1.150070.tar.gz
  ...

After installation, you should be able to run the script something like:

  shell% validate_manifest
  validate.pl [-chiov] [long options...] <filename>
          -c --config           path to the configuration file that defines the
                                checklist
          -o --output           write the validated CSV file to this file
          -i --write-invalid    write invalid rows only
          -v --verbose-errors   show full field descriptions in validation
                                error messages
          -h --help             print usage message
  shell%

You can use "validate_manifest -h" to see more detailed documentation.

Download the ontologies
-----------------------

The checklist requires that certain fields (e.g. location) contain ontology
terms. The validation script can check that values in your manifest are found in
the requires ontologies, but you need to download the ontology files and store
them locally first.

These are the three files that are needed:

http://purl.obolibrary.org/obo/subsets/envo-basic.obo
http://www.brenda-enzymes.info/ontology/tissue/tree/update/update_files/BrendaTissueOBO
http://purl.obolibrary.org/obo/gaz.obo

Note that the GAZ ontology is 180Mb.

Download the ontology files and put them in the same directory as the manifest
and the configuration files.

Build the manifest
------------------

The sample data must be formatted as a "comma-separated values" (CSV) file. If
you have sample data in Excel, you can export a CSV file by choosing

  File --> Save As... --> Format: Window Comma Separated (.csv)

If you are creating the CSV file using a script or similar, you can see an
example file in the bundle containing this readme.

Validate the manifest
---------------------

Run the "validate_manifest" script in the directory containing the checklist
configuration ("HICF_checklist.conf"), the manifest (e.g.
"example_manifest.csv") and the ontology files ("envo-basic.obo",
"BrendaTissueOBO", "gaz.obo").

  shell% validate_manifest -c HICF_checklist.conf example_manifest.csv
  'example_manifest.csv' is valid

This working manifest file is included with the checklist.

Error messages are appended to invalid rows as an extra column, so that you can
re-import the file into Excel and view the error messages along with the data.
If you find problems with your manifest, you can write out the invalid rows and
check the embedded error messages:

  shell% validate_manifest -c HICF_checklist.conf -o invalid_rows.csv -i broken_manifest.csv
  'broken_manifest.csv' is invalid. Found 1 invalid row.
  wrote only invalid rows from validated file to 'invalid_rows.csv'.
  shell% less invalid_rows.csv
  1,1,Example description,WTSI,703339,Staphylococcus aureus 04-02981,"Tate JG, Keane J",123,05/10/2013,GAZ:00444180,yes,Homo sapiens,healthy,BTO:0000645,,I,,630,,"tetracyclin;S;40,erythromycin;R;50;Peru",,,,,, [value in field 'collection_date' is not valid]

Here you can see that there was a single error on a single row of the manifest.
In this case the date was specified in an invalid format, using the default
Excel format (DD/MM/YYYY) rather than the required ISO format (e.g. 2013-10-05).

