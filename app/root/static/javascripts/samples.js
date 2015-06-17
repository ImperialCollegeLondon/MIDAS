
// samples.js
// jt6 20150517 WTSI

/* exported  samples*/

var samples = (function() {
  "use strict";

  return {

    // add listeners where needed
    setupTable: function() {

      $("#samples").dataTable( {
        // dom: "T<'clear'>lfrtip",
        serverSide: true,
        ajax: {
          url: window.location.href,
          data: function(d) {
            // add a param to signify that this request comes from DataTables
            d._dt = 1;
          }
        }
      } );

      $("#samples_filter input").on("input change", function(e) {
        var filterTerm = $(e.target).val();
        if ( filterTerm === undefined || filterTerm == "" ) {
          $("#filtered").hide();
          $("#all").show();
        } else {
          $("#filtered").show();
          $("#all").hide();
        }
      } );

      $("button.table-download-link").on("click", function(e) {
        var filterTerm = $("#samples_filter input").val(),
            dlFormat   = e.target.dataset.format,
            dlURL      = window.location.href;
        dlURL += "?dl=1";
        dlURL += "&content-type=" + encodeURIComponent(dlFormat);
        if ( filterTerm !== undefined && filterTerm != "" ) {
          dlURL += "&filter=" + encodeURIComponent(filterTerm);
        }
        console.debug( "redirecting to " + dlURL );
        window.location.href = dlURL;
      } );

    }
  };

})();

