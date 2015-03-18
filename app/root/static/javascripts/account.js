
// account.js
// jt6 20150310 WTSI

/* exported  account*/

var account = (function() {
  "use strict";

  return {

    // add listeners where needed
    wireButtons: function() {

      console.debug( "connecting password/key reset buttons" );

      $("#reset-password-button").on("click", function(e) {
        e.preventDefault();
        account.resetPassword();
      });

      $("#reset-key-button").on("click", function(e) {
        e.preventDefault();
        account.resetKey();
      });

    },

    resetPassword: function() {
      console.debug( "resetting password" );

      $("#reset-password-result").hide();

      $.ajax({
        type: "POST",
        url: "/account/resetpassword",
        data: $("#reset-password-form").serialize()
      })
      .done( function(data) {
        $("#reset-password-result-message").html(data.message);
        $("#reset-password-result").removeClass("alert-danger")
                                   .addClass("alert-success")
                                   .show();
        $("#reset-password-form")[0].reset();
        $("#newpass2")[0].blur();
      })
      .fail( function(jqXHR) {
        var data = jqXHR.responseJSON;
        $("#reset-password-result-message").html(data.error);
        $("#reset-password-result").removeClass("alert-success")
                                   .addClass("alert-danger")
                                   .show();
      });
    },

    resetKey: function() {
      console.debug( "resetting API key" );

      $("#reset-key-result").hide();

      $.ajax({
        type: "POST",
        url:  "/account/resetkey",
        data: $("#reset-key-form").serialize()
      })
      .done( function(data) {
        $("#apikey").val(data.key);
        $("#reset-key-result-message").html(data.message);
        $("#reset-key-result").removeClass("alert-danger")
                              .addClass("alert-success")
                              .show();
        $("#reset-password-form")[0].reset();
      })
      .fail ( function(jqXHR) {
        var data = jqXHR.responseJSON;
        $("#apikey").val("");
        $("#reset-key-result-message").html(data.error);
        $("#reset-key-result").removeClass("alert-success")
                              .addClass("alert-danger")
                              .show();
      });
    }
  };

})();

