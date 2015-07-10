
var login = require("./login.js");

login( function() {

  describe("Account management page", function() {

    it("should be available to logged-in user", function() {
      casper.thenOpen("http://localhost:3001/account")
      .waitForUrl(/account/, function() {
        "Account management".should.be.textInDOM
        "Reset your password".should.be.textInDOM
        "Generate a new API key".should.be.textInDOM
      });
    });

  });

  describe("Password reset form", function() {

    it("should show an error if password is not entered", function() {
      casper.click("#reset-password-button", function() {
        this.waitUntilVisible("#reset-password-result")
        .then(function() {
          "#reset-password-result".should.contain.text("You must enter all three passwords")
          "#reset-password-result".should.have.an.attribute("class")[0].that.equals("alert-danger")
        });
        // casper.then(function() {
        //   this.capture("form.png", { top: 0, left: 0, width: 1100, height: 1600 });
        // });
      });
    });

    it("should show an error if only one password is entered", function() {
      casper.fill("#reset-password-form", {
        oldpass: "badpassword"
      });
      casper.click("#reset-password-button", function() {
        this.waitUntilVisible("#reset-password-result", function() {
          this.then(function() {
            "#reset-password-result".should.contain.text("You must enter all three passwords")
          });
        });
      });
    });

    it("should show an error if only one new password is entered", function() {
      casper.fill("#reset-password-form", {
        oldpass: "password",
        newpass1: "newpassword"
      });
      casper.click("#reset-password-button", function() {
        this.waitUntilVisible("#reset-password-result", function() {
          this.then(function() {
            "#reset-password-result".should.contain.text("You must enter all three passwords")
          });
        });
      });
    });

    it("should show an error if new passwords do not match", function() {
      casper.fill("#reset-password-form", {
        oldpass: "password",
        newpass1: "newpassword",
        newpass1: "otherpassword"
      });
      casper.click("#reset-password-button", function() {
        this.waitUntilVisible("#reset-password-result", function() {
          this.then(function() {
            "#reset-password-result".should.contain.text("New passwords did not match")
          });
        });
      });
    });

    it("should show success with matching new passwords", function() {
      casper.fill("#reset-password-form", {
        oldpass: "password",
        newpass1: "newpassword",
        newpass1: "newpassword"
      });
      casper.click("#reset-password-button", function() {
        this.waitUntilVisible("#reset-password-result", function() {
          this.then(function() {
            "#reset-password-result".should.contain.text("Your password has been changed");
            "#reset-password-result".should.have.an.attribute("class")[0].that.equals("alert-success");

            // reset password to original value
            this.fill("#reset-password-form", {
              oldpass: "newpassword",
              newpass1: "password",
              newpass1: "password"
            });
          })
        });
      });
    });

  });

  describe("API key reset form", function() {

    it("should show an error if password is not entered", function() {
      casper.click("#reset-key-button", function() {
        this.waitUntilVisible("#reset-key-result")
        .then(function() {
          "#reset-key-result".should.contain.text("You must enter your current passwords")
          "#reset-key-result".should.have.an.attribute("class")[0].that.equals("alert-danger")
        });
      });
    });

    it("should show an error a bad password is entered", function() {
      casper.fill("#reset-key-form", {
        password: "badpassword",
      });
      casper.click("#reset-key-button", function() {
        this.waitUntilVisible("#reset-key-result", function() {
          this.then(function() {
            "#reset-key-result".should.contain.text("Invalid password. Please try again")
          });
        });
      });
    });

    it("should show success with good passwords", function() {
      casper.fill("#reset-key-form", {
        password: "password",
      });
      casper.click("#reset-key-button", function() {
        this.waitUntilVisible("#reset-key-result", function() {
          this.then(function() {
            "#reset-password-result".should.contain.text("Your API key has been reset");
            "#reset-password-result".should.have.an.attribute("class")[0].that.equals("alert-success");

            // reset password to original value
            this.fill("#reset-password-form", {
              oldpass: "newpassword",
              newpass1: "password",
              newpass1: "password"
            });
          })
        });
      });
    });

  });

});

