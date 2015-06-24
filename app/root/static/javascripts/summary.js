
// summary.js
// jt6 20150623 WTSI

/* exported summary */

var summary = (function() {
  "use strict";

  return {

    // set up the tables in the page
    setupTables: function() {
      summary.organismTable = $("#organism-table").DataTable( {
        dom: "t",
        scrollY: "20em",
        paging: false,
        ordering: true
      } );

      $("#sort-species").on("click", function() {
        var currentOrder = summary.organismTable.order(),
            newOrder     = currentOrder[0][1] === "asc" ? "desc" : "asc";
        summary.organismTable.order( [ 0, newOrder ] )
                             .draw();
      } );
      $("#sort-num-samples").on("click", function() {
        var currentOrder = summary.organismTable.order(),
            newOrder     = currentOrder[0][1] === "asc" ? "desc" : "asc";
        summary.organismTable.order( [ 1, newOrder ] )
                             .draw();
      } );
    }
  };

})();

