
Validating a sample manifest
============================

This document explains how to use the validate_manifest perl script to check
the contents of a sample manifest before deposition with the HICF sample data
repository.

Install the perl module and script
----------------------------------

Download the Perl module and script:

  https://www.midasuk.org/validator/Bio-Metadata-Validator-1.150850.tar.gz

The usual way to install a Perl module is something like this:

  shell% tar zxf Bio-Metadata-Validator-1.150850.tar.gz
  shell% cd Bio-Metadata-Validator-1.150850
  shell% perl Makefile.PL
  ...
  shell% make install
  ...

However, this module has quite a number of dependencies, so it may be easier to
use cpanm (see https://github.com/miyagawa/cpanminus) to install the tarball
directly. cpanm will detect and install the pre-requisites automatically:

  shell% cpanm Bio-Metadata-Validator-1.150850.tar.gz
  ...

After installation you should be able to run the script something like:

  shell% validate_manifest
  validate_manifest [-chiov] [long options...]
        -c --config           path to the configuration file that defines the
                              checklist
        -o --output           write the validated CSV file to this file
        -i --write-invalid    write invalid rows only
        -v --verbose-errors   show full field descriptions in validation
                              error messages
        -h --help             print usage message
  shell%

You can use validate_manifest -h to see more detailed documentation.

Download the ontologies and taxonomy data
-----------------------------------------

The checklist requires that certain fields (e.g. location) contain ontology
terms and others (e.g. scientific_name) contain valid scientific names or tax
IDs for organisms. The validation script can check that values in your manifest
are found in the required ontologies or the taxonomy tree, but you need to
download the data files and store them locally first.

These are the three ontology files that are needed:

  http://purl.obolibrary.org/obo/subsets/envo-basic.obo (0.5Mb)
  http://www.brenda-enzymes.info/ontology/tissue/tree/update/update_files/BrendaTissueOBO (1.8Mb)
  http://purl.obolibrary.org/obo/gaz.obo (180Mb)

There is one taxonomy file, but it is only available as a tar archive:

  ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz (30Mb)

After downloading the tar file, you need to extract the "names.dmp" file:

  shell% tar zxf taxdump.tar.gz names.dmp

If you change the names of the files for any reason, you will need to edit the
checklist configuration file accordingly.

Build your manifest
-------------------

Your sample data must be formatted as a "comma-separated values" (CSV) file. If
you have sample data in Excel, you can export a CSV file using:

  File --> Save As... --> Format: Window Comma Separated (.csv)

If you are creating the CSV file using a script or similar, you can see an
example file in the bundle containing the Perl module and README. You can
download a tar archive containing the manifest template and example manifests
in Excel and CSV formats.

Validate the manifest
---------------------

Download the checklist configuration file. It's easiest to run
validate_manifest in the directory containing the config file, your manifest,
and the ontology files ("envo-basic.obo", "BrendaTissueOBO", "gaz.obo").

  shell% validate_manifest -c HICF_checklist.conf example_manifest.csv
  'example_manifest.csv' is valid

Error messages are appended to invalid rows as an extra column, so that you can
re-import the file into Excel and view the error messages along with the data.
If you find problems with your manifest, you can write out the invalid rows and
check the embedded error messages:

  shell% validate_manifest -c HICF_checklist.conf -o invalid_rows.csv -i broken_manifest.csv
  'broken_manifest.csv' is invalid. Found 1 invalid row.
  wrote only invalid rows from validated file to 'invalid_rows.csv'.
  shell% less invalid_rows.csv
  1,1,Example description,CAMBRIDGE,703339,Staphylococcus aureus 04-02981,"Tate JG, Keane J",123,05/10/2013,GAZ:00444180,yes,Homo sapiens,healthy,BTO:0000645,inpatient,,I,,630,,"tetracyclin;S;40,erythromycin;R;50;Peru",,,,,, [value in field 'collection_date' is not valid]

Scrolling to the end of the line you can see that there was a single error on a
one row of the manifest. In this case the date was specified in an invalid
format, using the default Excel format (05/10/2013) rather than the required
ISO format (e.g. 2013-10-05).

Resources
---------

These are the files that you will need to run the validator:

https://www.midasuk.org/validator/Bio-Metadata-Validator-1.150850.tar.gz
    Perl module
https://www.midasuk.org/validator/HICF_checklist/00README.txt
    README containing this documentation
https://www.midasuk.org/validator/HICF_checklist/broken_manifest.csv
    example of an invalid manifest in CSV format
https://www.midasuk.org/validator/HICF_checklist/example_manifest.csv
    example of a valid manifest in CSV format
https://www.midasuk.org/validator/HICF_checklist/example_manifest.xlsx
    example of a valid manifest in Excel format
https://www.midasuk.org/validator/HICF_checklist/HICF_checklist.conf
    checklist configuration file
https://www.midasuk.org/validator/HICF_checklist/invalid_rows.csv
    invalid rows found when validating broken_manifest.csv
https://www.midasuk.org/validator/HICF_checklist/midas_manifest_v3.xlsx
    manifest template in Excel format
http://purl.obolibrary.org/obo/subsets/envo-basic.obo
    Environment ontology
http://www.brenda-enzymes.info/ontology/tissue/tree/update/update_files/BrendaTissueOBO (1.8Mb)
    BRENDA tissue ontology
http://purl.obolibrary.org/obo/gaz.obo (180Mb)
    Gazetteer ontology
ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
    NCBI taxonomy
 

jt6 20150326 WTSI

