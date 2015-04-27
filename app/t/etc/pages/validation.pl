# database definition used by t/pages/validation.t
{
  schema_class => 'Bio::HICF::Schema',
  resultsets => [ qw(
    Taxonomy
  ) ],
  fixture_sets => {
    main => [
      Taxonomy => [
        [ qw( tax_id name lft rgt parent_tax_id ) ],
        [ 287,"Pseudomonas aeruginosa",329528,330291,136841 ],
        [ 1764,"Mycobacterium avium",971345,971492,120793 ],
        [ 1766,"Mycobacterium fortuitum",964754,964765,1763 ],
        [ 1767,"Mycobacterium intracellulare",971493,971512,120793 ],
        [ 1768,"Mycobacterium kansasii",964766,964777,1763 ],
        [ 1773,"Mycobacterium tuberculosis",965111,970818,77643 ],
        [ 1774,"Mycobacterium chelonae",973487,973490,670516 ],
        [ 1778,"Mycobacterium gordonae",964834,964835,1763 ],
        [ 1780,"Mycobacterium malmoense",964838,964839,1763 ],
        [ 1781,"Mycobacterium marinum",964840,964853,1763 ],
        [ 1787,"Mycobacterium szulgai",964864,964865,1763 ],
        [ 1789,"Mycobacterium xenopi",964866,964873,1763 ],
        [ 33892,"Mycobacterium bovis BCG",965064,965095,1765 ],
        [ 33894,"Mycobacterium africanum",970823,970890,77643 ],
        [ 36809,"Mycobacterium abscessus",973498,973671,670506 ],
        [ 40324,"Stenotrophomonas maltophilia",426738,426813,995085 ],
        [ 77643,"Mycobacterium tuberculosis complex",965062,971157,1763 ],
        [ 1306155,"mixed culture",267739,268170,12908 ],
        [ 1578725,"Stenotrophomonas sp. L21878",428911,428912,40323 ],
      ],
    ],
  },
};
