
// validation.js
// jt6 20150424 WTSI

/* exported  validation*/

var validation = (function() {
  "use strict";

  return {

    // add listeners where needed
    addFormListener: function() {

      $("#validation-form").submit(function(event) {

        // reset the page; hide both result panels
        $("#validation-success").hide();
        $("#validation-fail").hide();
        $("#validation-error").hide();

        $("#validation-spinner").show();

        var formEl = document.forms.namedItem("validation-form"),
            action = formEl.action,
            formData = new FormData(formEl);

        $.ajax({
          type: "POST",
          url: action,
          data: formData,
          contentType: false,
          processData: false
        })
        .done(function(data) {
          if ( data.status === "valid" ) {
            $("#validation-success").show();
          } else if ( data.status === "invalid" ) {
            $("#invalid-download")[0].href = data.validatedFile;
            $("#validation-fail").show();
          }
        })
        .fail(function(data) {
          $("#validation-success").hide();
          $("#validation-fail").hide();
          $("#validation-error-message").html(data.responseText);
          $("#validation-error").show();
        })
        .complete(function() {
          $("#validation-spinner").hide();
        });

        event.preventDefault();
      });

    }

  };

})();

