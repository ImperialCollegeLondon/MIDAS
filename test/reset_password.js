
casper.test.begin("password change tests", 20, function(test) {

  casper.start("http://localhost:8000/logout");

  casper.then(function() {
    test.assertTitleMatch(/MIDAS/, "title matches");
    test.assertExists("#signInButton", "found sign-in button");
    test.assertDoesntExist("#signOutButton", "no sign-out button");
    this.click("#signInButton");
  });

  casper.then(function() {
    test.comment("sign in");
    this.fill("form[name='signin-form']", {
      username: "testuser",
      password: "password"
    });
    this.click("button[type='submit']");
  });

  casper.waitForSelector("span.signed-in > a", function() {
    test.comment("visit account page");
    this.click("span.signed-in > a");
  });

  casper.then(function() {
    test.assertTextExists("Account management", "on account management page");
    test.assertNotVisible("#reset-password-result", "error message div is hidden");
  });

  casper.then(function() {
    test.comment("submit with no passwords");
    this.click("#reset-password-button");
  });

  casper.waitForSelector("#reset-password-result", function() {
    test.assertVisible("#reset-password-result", "error message div is visible");
    test.assertTextExists("You must enter all three passwords", "got error message");
    var classes = this.getElementAttribute("#reset-password-result", "class");
    test.assertMatch(classes, /alert-danger/, "error div has 'alert-danger' class");
  });

  casper.then(function() {
    test.comment("submit with one bad password");
    this.fill("#reset-password-form", {
      oldpass: "badpassword"
    });
    this.click("#reset-password-button");
  });

  casper.waitForSelector("#reset-password-result", function() {
    test.assertVisible("#reset-password-result", "error message div is visible");
    test.assertTextExists("You must enter all three passwords", "got error message");
  });

  casper.then(function() {
    test.comment("submit with one good password");
    this.fill("#reset-password-form", {
      oldpass: "password"
    });
    this.click("#reset-password-button");
  });

  casper.waitForSelector("#reset-password-result", function() {
    test.assertVisible("#reset-password-result", "error message div is visible");
    test.assertTextExists("You must enter all three passwords", "got error message");
  });

  casper.then(function() {
    test.comment("submit with good password, one repeat password");
    this.fill("#reset-password-form", {
      oldpass:  "password",
      newpass1: "newpassword"
    });
    this.click("#reset-password-button");
    test.assertTextExists("You must enter all three passwords", "got error message");
  });

  casper.waitForSelector("#reset-password-result", function() {
    test.assertVisible("#reset-password-result", "error message div is visible");
    test.assertTextExists("You must enter all three passwords", "got error message");
  });

  casper.then(function() {
    test.comment("submit with good password, non-matching repeat passwords");
    this.fill("#reset-password-form", {
      oldpass:  "password",
      newpass1: "newpassword",
      newpass2: "otherpassword"
    });
    this.click("#reset-password-button");
  });

  casper.waitForSelector("#reset-password-result", function() {
    test.assertVisible("#reset-password-result", "error message div is visible");
    test.assertTextExists("New passwords did not match", "got error message");
  });

  casper.then(function() {
    test.comment("submit with good password, matching repeat passwords");
    this.fill("#reset-password-form", {
      oldpass:  "password",
      newpass1: "newpassword",
      newpass2: "newpassword"
    });
    this.click("#reset-password-button");
  });

  casper.waitForSelector("#reset-password-result", function() {
    test.assertVisible("#reset-password-result", "error message div is visible");
    test.assertTextExists("Your password has been changed", "got success message");
    var classes = this.getElementAttribute("#reset-password-result", "class");
    test.assertMatch(classes, /alert-success/, "error div has 'alert-success' class");
  });

  casper.then(function() {
    test.comment("reset password to original value");
    this.fill("#reset-password-form", {
      oldpass:  "newpassword",
      newpass1: "password",
      newpass2: "password"
    });
    this.click("#reset-password-button");
  });

  casper.run(function() {
    test.done();
  });

});

