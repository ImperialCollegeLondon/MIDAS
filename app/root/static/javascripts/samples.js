
// samples.js
// jt6 20150517 WTSI

/* exported  samples*/

var samples = (function() {
  "use strict";

  return {

    // build the contents of the row showing AMR data for a sample
    _formatAMR: function(d) {
      /*jshint camelcase: false */

      var table = [],
          equality,
          susceptibilityClass;

      table.push( "<table class='amrData table table-striped table-condensed'>" );
      table.push( "<thead><tr>" );
      table.push( "<th>Compound name</th>" );
      table.push( "<th><abbr title='Susceptible (S), Intermediate (I), Resistant (R)'>Susceptibility</abbr></th>" );
      table.push( "<th><abbr title='Minimum Inhibitory Concentration'>MIC</abbr> (<abbr title='milligrammes per litre'>mg/l</abbr>)</th>" );
      table.push( "</tr></thead>" );
      table.push( "<tbody>" );

      $.each( d.amr, function(i, amr) {
        switch ( amr.susceptibility ) {
          case "S": susceptibilityClass = "amrS"; break;
          case "I": susceptibilityClass = "amrI"; break;
          case "R": susceptibilityClass = "amrR";  break;
        }
        table.push( "<tr class='" + susceptibilityClass + "'>" );
        table.push( "<td class='amrName'>" + amr.antimicrobial_name + "</td>" );
        table.push( "<td class='amrSIR'>"  + amr.susceptibility + "</td>" );
        switch ( amr.equality ) {
          case "le": equality = "&le;"; break;
          case "lt": equality = "&lt;"; break;
          case "eq": equality = "";     break;
          case "gt": equality = "&gt;"; break;
          case "ge": equality = "&ge;"; break;
        }
        table.push( "<td class='amrMIC'>" + equality + amr.mic + "</td>" );
        table.push( "</tr>" );
      } );

      table.push( "</tbody></table>" );

      return table.join("");
    },

    // set up the samples table
    setupTable: function() {
      /*jshint camelcase: false */

      var samplesTable = $("#samples").DataTable( {
        // dom: "T<'clear'>lfrtip",
        serverSide: true,
        ajax: {
          url: window.location.href,
          data: function(d) {
            // add a param to signify that this request comes from DataTables
            d._dt = 1;
          }
        },
        columns: [
          {
            // sample_id
            render: function(data, type, row, meta) {
              return "<a href='/sample/" + row.sample_id + "'>" +
                     row.sample_id + "</a>";
            }
          },
          { data: "manifest_id" },
          {
            // scientific_name
            orderData: 2,
            render: function(data, type, row, meta) {
              return row.scientific_name + " (" + row.tax_id + ")";
            }
          },
          {
            //  tax_id
            data: "tax_id",
            visible: false
          },
          { data: "collection_date" },
          { data: "collected_at" },
          {
            // AMR data
            className: "amrCell text-center",
            orderable: false,
            render: function(data, type, row, meta) {
              if ( Object.keys(row.amr).length > 0 ) {
                return "<i title='Sample has AMR data' class='hasAMR fa fa-plus-square'></i>";
              } else {
                return "<i title='No AMR data for sample' class='noAMR fa fa-times'></i>";
              }
            }
          }
        ]
      } );

      // add a listener to show AMR data for samples that possess it
      samplesTable.on("draw", function() {

        $("#samples tbody").on("click", "td.amrCell", function() {
          var tr,
              row,
              hasAMR = $(this).children(".hasAMR");

          if ( hasAMR.length < 1 ) {
            return;
          }

          tr  = $(this).closest("tr");
          row = samplesTable.row(tr);

          if ( row.child.isShown() ) {
            row.child.hide();
            tr.removeClass("shown");
            hasAMR.removeClass("fa-minus-square")
                  .addClass("fa-plus-square");
          } else {
            row.child( samples._formatAMR( row.data() ) ).show();
            tr.addClass("shown");
            hasAMR.removeClass("fa-plus-square")
                  .addClass("fa-minus-square");
          }
        } );

      } );

      // listen for changes to the "search" input that filters the table and show/hide
      // the text in the "Download data" label
      $("#samples_filter input").on("input change", function(e) {
        var filterTerm = $(e.target).val();
        if ( filterTerm === undefined || filterTerm === "" ) {
          $("#filtered").hide();
          $("#all").show();
        } else {
          $("#filtered").show();
          $("#all").hide();
        }
      } );

      // listen for clicks on the download buttons. If there's a click, we build the
      // URL to download the specified format, then tell the browser to retrieve it
      $("button.table-download-link").on("click", function(e) {
        var filterTerm = $("#samples_filter input").val(),
            dlFormat   = e.target.dataset.format,
            dlURL      = window.location.href;
        dlURL += "?dl=1";
        dlURL += "&content-type=" + encodeURIComponent(dlFormat);
        if ( filterTerm !== undefined && filterTerm !== "" ) {
          dlURL += "&filter=" + encodeURIComponent(filterTerm);
        }
        console.debug( "redirecting to " + dlURL );
        window.location.href = dlURL;
      } );

    }
  };

})();

