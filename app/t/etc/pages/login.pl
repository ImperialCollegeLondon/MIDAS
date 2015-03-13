# database definition used by t/pages/account.t
{
  schema_class => 'Bio::HICF::Schema',
  resultsets => [ qw(
    User
  ) ],
  fixture_sets => {
    main => [
      User => [
        [ qw( username passphrase displayname email roles api_key ) ],
        [ 'testuser', 'password', 'Test User', 'testuser@sanger.ac.uk', 'user', 'HrZIg2JG53r236okEhHpBrCRa9U1L4fm' ],
      ],
    ],
  },
};
