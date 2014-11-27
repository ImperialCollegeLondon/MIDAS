
// index.js
// jt6 20141119 WTSI

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

      $("#signInSubmitButton").on( "click", function() {
        $("#signInModal").modal("hide");
        $("#signInButton").button("signedin")
                          .prop("disabled", true );
      } );
    }

  };

})();

