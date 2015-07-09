
var login = require("./login.js");

login( function() {

  describe( "Samples page", function() {

    it("should be available to logged-in user", function() {
      casper.thenOpen("http://localhost:3001/samples")

      casper.then( function() {
        this.evaluate(function(done) {
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

    it("should have expected content", function() {
      "#samples-table > tbody > tr:nth-child(1) > td:nth-child(1) > a:nth-child(1)"
        .should.contain.text("1")
    });

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

    it("should have drop-downs for AMR", function() {
      "#samples-table > tbody > tr:nth-child(1) > td.amrCell > i.hasAMR"
        .should.be.inDOM;
      casper.click("#samples-table > tbody > tr:nth-child(1) > td.amrCell > i.hasAMR", function() {
        this.waitForSelector( "table.amrData")
            .then(function() {
              "td.amrName".should.contain.text("am1");
              "tr.amrS".should.be.inDOM;
            });
      });
    });

    it("should be searchable", function() {
      casper.fillSelectors( "#samples-table_filter", { "input": "Homo" }, false );
      casper.waitForSelectorTextChange( "#samples-table_info", function() {
        "#samples-table_info".should.contain.text("filtered");
        "#samples-table_info".should.contain.text("1 to 4");
        "$('#samples-table > tbody > tr').length".should.evaluate.to.equal(4);
      })

    });

    it("should do paging", function() {
      // should have 10 rows to start with
      casper.fillSelectors( "#samples-table_filter", { "input": "" }, false );
      casper.waitForSelectorTextChange( "#samples-table_info", function() {
        "$('#samples-table > tbody > tr').length".should.evaluate.to.equal(10);
      })

      // click "page 2" button and make sure we then only have 1 row
      casper.click("#samples-table_paginate a[data-dt-idx='2']", function() {
        this.waitForSelectorTextChange( "#samples-table_info", function() {
          "#samples-table_info".should.contain.text("Showing 11 to 11");
        "$('#samples-table > tbody > tr').length".should.evaluate.to.equal(1);
        });
      });

      // reset the table
      casper.click("#samples-table_paginate a[data-dt-idx='0']", function() {
        this.waitForSelectorTextChange( "#samples-table_info", function() {
          "#samples-table_info".should.contain.text("Showing 1 to 10");
        "$('#samples-table > tbody > tr').length".should.evaluate.to.equal(10);
        });
      });
    });

//     it("should support page lengths", function() {
//         var state = this.evaluate(function(done) {
//           $("#samples-table").dataTable().api().state.clear();
//         });
//
//
// $("#samples-table").dataTable().api().page.len(25).draw()
//       casper.click("#samples-table_length a[data-dt-idx='0']", function() {
//         this.waitForSelectorTextChange( "#samples-table_info", function() {
//           "#samples-table_info".should.contain.text("Showing 1 to 10");
//         "$('#samples-table > tbody > tr').length".should.evaluate.to.equal(10);
//         });
//       });
//     });

  });

});

