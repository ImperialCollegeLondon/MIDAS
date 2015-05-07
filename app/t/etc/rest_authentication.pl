# database definition used by t/rest_authentication.t
{
  schema_class => 'Bio::HICF::Schema',
  resultsets => [ qw(
    User
  ) ],
  fixture_sets => {
    main => [
      User => [
        [ qw( username passphrase displayname email roles api_key ) ],
        [ 'testuser', 'password', 'Test User', 'testuser@sanger.ac.uk', 'user', '2566ZD3k4SVdJfGkdXJQUj6B4aPoq2Rf' ],
      ],
    ],
  },
};
