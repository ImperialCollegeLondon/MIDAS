
// login.js
// jt6 20150212 WTSI

/* exported  login*/

var login = (function() {
  "use strict";

  return {

    // add listeners where needed
    wireButtons: function() {

      $("#signInButton").on("click", function() {
        window.location = "/login";
      });

      $("#signOutButton").on("click", function() {
        window.location = "/logout";
      });

    }
  };

})();

