use strict;
use warnings;

use MIDAS;

my $app = MIDAS->apply_default_middlewares(MIDAS->psgi_app);
$app;

