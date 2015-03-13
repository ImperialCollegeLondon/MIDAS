
// 404.js
// jt6 20150313 WTSI

/* exported  fourohfour*/

var fourohfour = (function() {
  "use strict";

  return {

    wireButtons: function() {

      $("#backLink").on("click", function(e) {
        history.go(-1);
        e.preventDefault();
      });

    }
  };

})();

