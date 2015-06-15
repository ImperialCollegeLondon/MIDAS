
// util.js
// jt6 20141119 WTSI
//
// see http://viget.com/inspire/extending-paul-irishs-comprehensive-dom-ready-execution

/* global validation,fourohfour,login,account */
/* exported HICF */

var HICF = {
  common: {
    init: function() {
      "use strict";
      // application-wide code
      // console.debug( "common.init: application-wide init code" );
      login.wireButtons();

      // TODO could inline the trivial functions like "wireButtons" here,
      // TODO rather than having a separate controller for them, but it's
      // TODO probably worth having a full blown controller when the code
      // TODO gets more complex.
    }
  },

  validation: {
    init: function() {
      "use strict";
      validation.addFormListener();
    }
  },

  fourohfour: {
    init: function() {
      "use strict";
      fourohfour.wireButtons();
    }
  },

  account: {
    init: function() {
      "use strict";
      // controller-wide code
      // console.debug( "account.init: init code specific to the account page" );
      account.wireButtons();
    },

    someAction: function() {
      "use strict";
      // action-specific code
      // console.debug( "index.clicked: action-specific code" );
    }
  },

  samples: {
    init: function() {
      "use strict";
      $("#samples").dataTable( {
        dom: "T<'clear'>lfrtip",
        serverSide: true,
        ajax: {
          url: "/samples",
          data: function(d) {
            // add a param to signify that this request comes from DataTables
            d._dt = 1;
          }
        }
      } );
    }
  }

  // ADDING NEW PAGES
  // if we add a new page to the site and that page uses javascript, we also
  // need to add a new javascript controller, a JS function that fires when a
  // page loads and handles setting up the JS code for that page. The steps
  // are:
  //   1. either:
  //        - create a new ".js" file for the page (if there's a lot of code)
  //      or
  //        - add a new method to the HICF object above (if there's not much code)
  //   2. set the "jscontroller" key in the stash to point at the file/method
  //      that we just created
  //
  // If we create a new JS file, it has to be included in the <script> tags in
  // "wrapper.tt" for it to be loaded and, later, to be concatenated into
  // "site.js"

};

var UTIL = {
  exec: function( controller, action ) {
    "use strict";

    var namespace = HICF;
    action = ( action === undefined ) ? "init" : action;

    if ( controller !== "" &&
         namespace[controller] &&
         typeof namespace[controller][action] === "function" ) {
      namespace[controller][action]();
    }
  },

  init: function() {
    "use strict";

    var body       = document.body,
        controller = body.dataset.controller;
        // action     = body.dataset.action;

        // old-style calls to get data-* attribute values:
        // controller = body.getAttribute( "data-controller" ),
        // action     = body.getAttribute( "data-action" );

    UTIL.exec( "common" );
    UTIL.exec( controller );         // run the init method first...
    // UTIL.exec( controller, action ); // then the specified method
  }
};

$( document ).ready( UTIL.init );

