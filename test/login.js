
var config = require("./config.js");

module.exports = function(testSuite) {

  describe("Sign in", function() {

    before( function() {
      casper.start("http://localhost:3001")
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
          { username: config.user.username,
            password: config.user.password },
          true
        );
      });
    });

    it("should be able to run tests requiring logged-in user", function() {
      casper.then(function() {
        testSuite.call(casper);
      });
    });

  });

};

