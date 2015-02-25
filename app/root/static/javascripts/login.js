
// login.js
// jt6 20150212 WTSI

/* exported  login*/

var login = (function() {
  "use strict";

  return {

    // add listeners where needed
    wireButtons: function() {
      $("#signInSubmitButton").on( "click", function() {
        $("#signInModal").modal("hide");
        $("#signInButton").button("signedin")
        .prop("disabled", true );
      } );
      // $("#signOutButton").click(this.signOut);
    },

    // callback for google+ sign in button
    // signInCallback: function(authResult) {
    //
    //   if ( authResult.code ) {
    //     console.info( "login.signInCallback: signed in: " + authResult.code );
    //
    //     $.ajax({
    //       type: "POST",
    //       url: "/connect?state=" + $("#signInButtons")[0].dataset.state,
    //       contentType: "application/octet-stream; charset=utf-8",
    //       processData: false,
    //       data: authResult.code
    //     })
    //     .done(function(result) {
    //       console.info( "login.signInCallback: server-side connection succeeded: ", result );
    //       if ( $("#loginMessage").length ) {
    //         var returnUrl = $("#loginMessage")[0].dataset.returnurl;
    //         if ( returnUrl !== undefined ) {
    //           console.info( "login.signInCallback: redirecting to original page (" + returnUrl + ")" );
    //           window.location = decodeURIComponent( returnUrl );
    //         }
    //       }
    //       $("#signInButton").hide();
    //       $("#signOutButton").show();
    //     })
    //     .fail(function(jqXHR, error) {
    //       console.error( "login.signInCallback: server-side connection failed: ", error );
    //       $("#signInButton").show();
    //       $("#signOutButton").hide();
    //     });
    //
    //   } else if (authResult.error) {
    //     console.warn( "login.signInCallback: there was an error while signing in: ",
    //                   authResult.error );
    //     $("#signInButton").show();
    //     $("#signOutButton").hide();
    //   }
    // },

    // sign out of google+
    // signOut: function() {
    //   console.info("login.signOut: signing out");
    //
    //   $.ajax({
    //     type: "POST",
    //     url: "/disconnect?state=" + $("#signInButtons")[0].dataset.state,
    //     async: false,
    //     success: function(result) {
    //       console.warn( "login.signOut: server-side disconnection succeeded: ", result );
    //       window.location = "/";
    //       $("#signInButton").show();
    //       $("#signOutButton").hide();
    //     },
    //     error: function(jqXHR, error) {
    //       console.warn( "login.signOut: server-side disconnection failed: ", error );
    //     }
    //   });
    // }
  };

})();

// function signInCallback(authResult) {
//   "use strict";
//   login.signInCallback(authResult);
// }
