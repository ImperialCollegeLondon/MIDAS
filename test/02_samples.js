
var login = require("./login.js");

login( function() {

  describe( "Samples page", function() {

    it("should be available to logged-in user", function() {
      casper.thenOpen("http://localhost:3001/samples")

      casper.then( function() {
        var state = this.evaluate(function(done) {
          $("#samples-table").dataTable().api().state.clear();
        });
        // this.capture("no_canary.png", { top: 0, left: 0, width: 1100, height: 1600 });
      })
      .thenOpen("http://localhost:3001/samples")

    });

    it("should have correct content", function() {
      "HICF samples".should.be.textInDOM
      "Scroll or drag".should.be.textInDOM
      "#samples-table_length".should.be.inDOM
      "#samples-table".should.be.inDOM
      "#samples-table_info".should.be.inDOM
    });

  });

  describe( "Samples table", function() {
    it("should have drop-downs for AMR", function() {
      "#samples-table > tbody > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)"
        .should.contain.text("1")
    });

    // it("should have drop-downs for AMR", function() {
    //   "#samples-table > tbody > tr:nth-child(1) > td.amrCell > i.hasAMR"
    //     .should.be.inDOM;
    // });

    it("should be sortable", function() {

      casper.click("#samples-table > thead > tr > th:nth-child(1)", function() {
        this.waitForSelectorTextChange( "#samples-table > tbody > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)")
            .then(function() {
              "#samples-table > tbody > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)"
                .should.contain.text("11")
            });
      });

      casper.click("#samples-table > thead > tr > th:nth-child(1)", function() {
        this.waitForSelectorTextChange( "#samples-table > tbody > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)")
            .then(function() {
              "#samples-table > tbody > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)"
                .should.contain.text("1")
            });
      });

    });

    // it("should be sorted", function() {
    //   "#samples-table > tbody > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)"
    //     .should.contain.text("11")
    // });

  });

});

