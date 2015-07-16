
module.exports = function(testSuite) {

  describe("Sign in", function() {

    before( function() {
      casper.start("http://localhost:3001")
      .viewport( 1100, 900 )
      .on( 'page.error', function (msg, trace) {
        this.echo( 'Browser JS error: ' + msg, 'ERROR' );
      })
      // uncomment to echo browser console debug messages and alerts to
      // the shell that's running the tests
      // .on('remote.message', function(msg) {
      //   this.echo('Debug: ' + msg);
      // })
      // .on('remote.alert', function(msg) {
      //   this.echo('Alert: ' + msg);
      // })
      .thenOpen("http://localhost:3001/logout");
    });

    // make sure the user is signed out first
    it("should start logged out", function() {
      "#signInButton".should.be.inDOM;
    });

    it("should be on sign in page", function() {
      casper.thenOpen("http://localhost:3001/login", function() {
        "MIDAS".should.matchTitle;
        "Sign in".should.be.textInDOM;
      });
    });

    it("should be able to sign in", function() {
      casper.then( function() {
        "form[name='signin-form']".should.be.inDOM.and.be.visible;
        this.fill(
          "form[name='signin-form']",
          { username: "testuser",
            password: "password" },
          true
        );
      });
    });

    it("should be able to run tests requiring logged-in user", function() {
      casper.then(function() {
        testSuite.call();
      });
    });

  });

};

