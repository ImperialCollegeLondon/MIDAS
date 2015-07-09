
# HICF website

This is the web front end for the [MIDAS](https://www.midasuk.org/) sample
metadata repository, funded by the [Human Innovation Challenge
Fund](http://www.wellcome.ac.uk/Funding/Innovations/Awards/Health-Innovation-Challenge-Fund/index.htm).
The website is a [Catalyst](http://www.catalystframework.org) application,
backed by a relational database (we use [MySQL](https://www.mysql.com)).

## Installation

### Clone the repo:

  ```
  git clone https://github.com/sanger-pathogens/MIDAS.git
  ```

### Install prerequisites

#### CPAN modules

The webapp requires, at a minimum, the following Perl modules:

* Catalyst::Runtime
* DBIx::Class
* Template
* [Bio::Metadata::Validator](https://github.com/sanger-pathogens/Bio-Metadata-Validator)
* [Bio::HICF::Schema](https://github.com/sanger-pathogens/Bio-HICF-Schema)

For now there is no definitive list of lesser dependencies. Start the app and
enjoy a game of whack-a-mole with CPAN.

#### Build tools

We use several nodejs-based build tools, coordinated by
[Grunt](http://gruntjs.com). You'll need to install several dependencies:

* [node.js](http://nodejs.org/)
* [sass](http://sass-lang.com/)
* [glue](http://gluecss.com/)
* [mocha-casperjs](https://www.npmjs.com/package/mocha-casperjs)
* [casper-chai](https://github.com/brianmhunt/casper-chai)

Start with node/npm and install the rest using

```bash
npm install -g grunt
```

and similar. For OS X, the easiest way to install way to install node
is using [Homebrew](http://brew.sh/).

#### Install node packages

The checkout contains a `package.json` package list, which can be
handed to `npm`:

```bash
cd MIDAS
npm install
```

(before running `npm install` you need to configure proxies:

```bash
export http_proxy=http://<proxy host>:<proxy port>
export https_proxy=http://<proxy host>:<proxy port>
```

otherwise downloading packages through the firewall fails.)

You may also need to install `grunt-cli` as a global package:

```bash
npm install -g grunt-cli
```

### Testing

There are two sets of tests. There are Perl tests that exercise the webapp
and its integration with the DB, and JS tests that test the front-end.

#### Perl tests

The perl tests check the page contents and API:

```bash
CATALYST_DEBUG=0 DBIC_TRACE=0 prove -lr t
```

You can turn on catalyst debugging and DBIC query logging by adding
environment variables to the command line:

```bash
CATALYST_DEBUG=1 DBIC_TRACE=1 prove -lr t
```

The output will be significantly more verbose.

#### Front-end tests

The front-end tests use the [Mocha](http://mochajs.org/) testing
framework and the [ChaiJS](http://chaijs.com/) assertion library. We use
[CasperJS](http://casperjs.org), a headless WebKit browser, to test the
front-end javascript. The interaction between Mocha and CasperJS is
coordinated by [mocha-casperjs](https://www.npmjs.com/package/mocha-casperjs).

The Perl tests start a headless server and use that, but the front-end
tests need a server to be running already. Start it using the
`run_test_server.sh` script:

```bash
cd MIDAS/app
sh run_test_server.sh
```

Run the tests themselves like:

```bash
cd MIDAS/test
mocha-casperjs 01_summary.js
```

