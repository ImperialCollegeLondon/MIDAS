
// index.js
// jt6 20141119 WTSI

/* global    console */
/* exported  indexPage */

var indexPage = (function() {
  "use strict";

  // var privateVar = "private";
  //
  // var privateMethod = function() {
  //   console.log( "this is a private method" );
  // };

  return {

    // publicProperty: "public",
    //
    // publicMethod: function(msg) {
    //   console.log( "this is a public method; msg: |" + msg + "|" );
    //   console.debug( "the private method returns:    |" + privateMethod() + "|" );
    //   console.debug( "the private variable contains: |" + privateVar + "|" );
    //   console.debug( "the public property contains:  |" + this.publicProperty + "|" );
    // },

    wireUI: function() {
      console.debug( "wiring in index page UI elements" );

      $("#signInSubmitButton").on( "click", function() {
        console.debug( "CLICKED sign in submission button" );
        $("#signInModal").modal("hide");
        $("#signInButton").button("signed-in")
                          .prop("disabled", true );
      } );
    }

  };

})();

