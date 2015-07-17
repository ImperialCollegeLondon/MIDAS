
var login = require("./login.js");

login( function() {

  describe( "Sample page", function() {

    it("should be available to logged-in user", function() {
      casper.thenOpen("http://localhost:3001/sample/1");
    });

    it("should have correct content", function() {
      "Sample 1".should.be.textInDOM
      "Sample metadata".should.be.textInDOM
      "Antimicrobial resistance".should.be.textInDOM
    });

    it("should have sensible metadata table", function() {
      "$('#metadata > tbody > tr').length".should.evaluate.to.equal(20)
      "#metadata > tbody:nth-child(2) > tr:nth-child(1) > td:nth-child(2) > a:nth-child(1)"
        .should.contain.text("data:1")
    });

    it("should have tooltips", function() {
      var triggerBounds = casper.getElementBounds("#metadata > tbody:nth-child(2) > tr:nth-child(1) > td:nth-child(1) > div:nth-child(1)"),
          x = triggerBounds.left + triggerBounds.width  / 2,
          y = triggerBounds.top  + triggerBounds.height / 2;
      casper.mouse.move( x, y );
      "div[role='tooltip']".should.be.visible;
    });

    it("should have sensible AMR table", function() {
      "$('#amr > tbody > tr').length".should.evaluate.to.equal(1)
      // the text gets capitalised by the CSS
      "#amr > tbody:nth-child(2) > tr:nth-child(1) > td:nth-child(1)"
        .should.contain.text("am1")
    });

  });

});

