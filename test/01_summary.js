
var login = require("./login.js");

login( function() {

  describe( "Summary page", function() {

    it("should be available to logged-in user", function() {
      casper.thenOpen("http://localhost:3001/summary")
      // casper.viewport( 1100, 900 )
      //       .then( function() {
      //   this.capture("summary.png", {
      //     top: 0,
      //     left: 0,
      //     width: 1100,
      //     height: 1600
      //   });
      // });
    });

    it("should have correct content", function() {
      casper.thenOpen("http://localhost:3001/summary");
      "HICF sample summary".should.be.textInDOM
      "#summary > p a:nth-child(1)".should.contain.text("11")
    });

    it("should have organism table", function() {
      "#organism-table > tbody > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)"
        .should.have.text("Bos taurus")
      "#susceptibility-table > tbody > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)"
        .should.have.text("Susceptible")
      "#compound-table > tbody > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)"
        .should.contain.text("Am1")
      "#sites-table > tbody > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)"
        .should.have.text("Cambridge")
    });

  });

  describe( "Organism table", function() {

    it("should be sortable by 'sort species' link", function() {
      casper.click("#sort-species")
      "#organism-table > tbody > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)"
        .should.have.text("Mycobacterium tuberculosis complex")
      casper.click("#sort-species")
      "#organism-table > tbody > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)"
        .should.have.text("Bos taurus")
    });

    it("should be sortable by 'sort counts' link", function() {
      casper.click("#sort-num-samples")
      "#organism-table > tbody > tr:nth-child(1) > td:nth-child(2) > a:nth-child(1)"
        .should.contain.text("4")
      casper.click("#sort-num-samples")
      "#organism-table > tbody > tr:nth-child(1) > td:nth-child(2) > a:nth-child(1)"
        .should.contain.text("1")
    });

  });

});

