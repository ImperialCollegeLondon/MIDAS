
// util.js
// jt6 20141119 WTSI
//
// see http://viget.com/inspire/extending-paul-irishs-comprehensive-dom-ready-execution

/* global indexPage */
/* exported HICF */

var HICF = {
  common: {
    init: function() {
      "use strict";
      // application-wide code
      console.debug( "common.init: application-wide init code" );
      login.wireButtons();
    }
  },

  index: {
    init: function() {
      "use strict";
      // controller-wide code
      console.debug( "index.init: controller-wide init code" );
    },

    someAction: function() {
      "use strict";
      // action-specific code
      console.debug( "index.clicked: action-specific code" );
    }
  }
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
        controller = body.dataset.controller,
        action     = body.dataset.action;
        // controller = body.getAttribute( "data-controller" ),
        // action     = body.getAttribute( "data-action" );

    UTIL.exec( "common" );
    UTIL.exec( controller );         // run the init method first...
    // UTIL.exec( controller, action ); // then the specified method
  }
};

$( document ).ready( UTIL.init );

