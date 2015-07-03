
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

      table.push( "<div class='row'><div class='col-md-offset-5 col-md-3'>" );
      table.push( "<table class='amrData table table-striped table-condensed'>" );
      table.push( "<thead><tr>" );
      table.push( "<th>Compound name</th>" );
      table.push( "<th><abbr title='Susceptible (S), Intermediate (I), Resistant (R)'>Susceptibility</abbr></th>" );
      table.push( "<th><abbr title='Minimum Inhibitory Concentration'>MIC</abbr> (<abbr title='milligrammes per litre'>mg/l</abbr>)</th>" );
      table.push( "</tr></thead>" );
      table.push( "<tbody>" );

      $.each( d.amr, function(i, amr) {
        if ( amr.susceptibility.match("[SIR]") ) {
          susceptibilityClass = "amr" + amr.susceptibility;
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
      table.push( "</div></div>" );

      return table.join("");
    },

    // set up the samples table
    setupTable: function() {
      /*jshint camelcase: false */

      var renderer = function(data, type, row, meta) {
        var rv;
        switch ( data ) {
          case "not available: not collected":
          case "not available: restricted access":
          case "not available: to be reported later":
          case "not applicable":
          case "obscured":
          case "temporarily obscured":
            rv = "<span class='na'>"+data+"</span>";
            break;
          case null:
          case "":
            rv = "<span class='na'>n/a</span>";
            break;
          default:
            rv = data;
        }
        return rv;
      };

      var samplesTable = $("#samples-table").DataTable( {
        // dom: "T<'clear'>lfrtip",
        serverSide: true,
        stateSave: true,
        stateDuration: 300,// -1 for session duration
        ajax: {
          url: window.location.href,
          data: function(d) {
            // add a param to signify that this request comes from DataTables
            d._dt = 1;
          },
          error: function(e) {
            if ( e.status === 401 ) {
              alert("Your session has expired. Please sign in again.");
              location.reload(true);
            }
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
          {
            // manifest_id
            render: function(data, type, row, meta) {
              return "<a title='Show only samples from this manifest' " +
                     "href='/samples?filter=" + row.manifest_id + "'>" +
                     row.manifest_id + "</a>";
            }
          },
          { data: "raw_data_accession", render: renderer },
          { data: "sample_accession",   render: renderer },
          {
            // sample_description
            render: function(data, type, row, meta) {
              var op = row.sample_description || "";
              if ( op.length > 10 ) {
                op = "<span class='expansion truncated'>" + op.substr(0, 10) +
                     "<a title='See more'>&hellip;</a>" +
                     "</span>" +
                     "<span class='expansion fullLength'>" + op +
                     " <a title='See less'>(hide)</a>" +
                     "</span>";
              }
              return op;
            }
          },
          { data: "collected_at", render: renderer },
          { data: "tax_id", visible: false },
          {
            // scientific_name
            render: function(data, type, row, meta) {
              return row.scientific_name + " (" + row.tax_id + ")";
            }
          },
          { data: "collected_by",            render: renderer },
          { data: "source",                  render: renderer },
          { data: "collection_date",         render: renderer },
          { data: "location",                render: renderer },
          { data: "host_associated",         render: renderer },
          { data: "specific_host",           render: renderer },
          { data: "host_disease_status",     render: renderer },
          { data: "host_isolation_source",   render: renderer },
          { data: "patient_location",        render: renderer },
          { data: "isolation_source",        render: renderer },
          { data: "serovar",                 render: renderer },
          { data: "other_classification",    render: renderer },
          { data: "strain",                  render: renderer },
          { data: "isolate",                 render: renderer },
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

        $("#samples-table tbody").on("click", "td.amrCell", function() {
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

        $("#samples-table span.expansion > a").on("click", function(e) {
          var link = e.target,
              parentSpan = link.closest("span"),
              siblingSpan = $(parentSpan).siblings()[0];
          $(parentSpan).toggle();
          $(siblingSpan).toggle();
        } );

      } );

      // listen for a re-draw; check the input that filters the table and
      // show/hide the text in the "Download data" label
      samplesTable.on("draw.dt", function(e, settings) {
        if ( samplesTable.search() !== "" ) {
          var filteredCount = samplesTable.page.info().recordsDisplay;
          $("#filtered").show();
          $("#filtered-count").html(" (" + filteredCount + " rows)").show();
          $("#all").hide();
        } else {
          $("#filtered").hide();
          $("#filtered-count").hide();
          $("#all").show();
        }
      } );

      // make the table draggable
      $("#samples-table_wrapper").draggable({
        cursor: "move",
        scroll: true,
        axis:   "x"
      });

      // listen for clicks on the download buttons. If there's a click, we build the
      // URL to download the specified format, then tell the browser to retrieve it
      $("button.table-download-link").on("click", function(e) {
        var filterTerm = $("#samples-table_filter input").val(),
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

