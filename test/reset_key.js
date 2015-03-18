
casper.test.begin("API key change tests", 13, function(test) {

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
    test.assertNotVisible("#reset-key-result", "error message div is hidden");
  });

  casper.then(function() {
    test.comment("submit with no password");
    this.click("#reset-key-button");
  });

  casper.waitForSelector("#reset-key-result", function() {
    test.assertVisible("#reset-key-result", "error message div is visible");
    test.assertTextExists("You must enter your current password", "got error message");
    var classes = this.getElementAttribute("#reset-key-result", "class");
    test.assertMatch(classes, /alert-danger/, "error div has 'alert-danger' class");
  });

  casper.then(function() {
    test.comment("submit with one bad password");
    this.fill("#reset-key-form", {
      password: "badpassword"
    });
    this.click("#reset-key-button");
  });

  casper.waitForSelector("#reset-key-result", function() {
    test.assertVisible("#reset-key-result", "error message div is visible");
    test.assertTextExists("Invalid password. Please try again", "got error message");
  });

  casper.then(function() {
    test.comment("submit with good password");
    this.fill("#reset-key-form", {
      password: "password"
    });
    this.click("#reset-key-button");
  });

  casper.waitForSelector("#reset-key-result", function() {
    test.assertVisible("#reset-key-result", "error message div is visible");
    test.assertTextExists("Your API key has been reset", "got success message");
    var classes = this.getElementAttribute("#reset-key-result", "class");
    test.assertMatch(classes, /alert-success/, "error div has 'alert-success' class");
  });

  casper.run(function() {
    test.done();
  });

});

