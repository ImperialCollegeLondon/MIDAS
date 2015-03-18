
casper.test.begin("login functionality tests", 15, function(test) {

  casper.start("http://localhost:8000/");

  casper.then(function() {
    test.assertTitleMatch(/MIDAS/, "title matches");
    test.assertExists("#signInButton", "found sign-in button");
    test.assertDoesntExist("#signOutButton", "no sign-out button");
  });

  casper.then(function() {
    test.comment("click sign-in button");
    this.click("#signInButton");
  });

  casper.then(function() {
    test.assertExists("h2", "Found page title");
    test.assertSelectorHasText("h2", "Sign in", "clicking sign-in button takes us to the login page");
  });

  casper.then(function() {
    test.comment("add username but no password");
    this.fill("form[name='signin-form']", { username: "testuser" } );
    this.click("button[type='submit']");
  });

  casper.then(function() {
    test.assertSelectorHasText("h2", "Sign in", "still on sign-in page");
    test.assertTextExists("Wrong username or password", "got expected error message");
  });

  casper.then(function() {
    test.comment("add username but bad password");
    this.fill("form[name='signin-form']", {
      username: "testuser",
      password: "badpassword"
    });
    this.click("button[type='submit']");
  });

  casper.then(function() {
    test.assertSelectorHasText("h2", "Sign in", "still on sign-in page");
    test.assertTextExists("Wrong username or password", "got expected error message");
  });

  casper.then(function() {
    test.comment("add valid username and password");
    this.fill("form[name='signin-form']", {
      username: "testuser",
      password: "password"
    });
    this.click("button[type='submit']");
  });

  casper.then(function() {
    test.assertTextExists("Working to provide tools for the rapid identification", "redirected to home page");
    test.assertDoesntExist("#signInButton", "no sign-in button");
    test.assertExists("#signOutButton", "found sign-out button");
  });

  casper.then(function() {
    test.comment("sign out");
    this.click("#signOutButton");
  });

  casper.then(function() {
    test.assertTextExists("Working to provide tools for the rapid identification", "redirected to home page");
    test.assertExists("#signInButton", "found sign-in button");
    test.assertDoesntExist("#signOutButton", "no sign-out button");
  });

  casper.run(function() {
    test.done();
  });

});

