
describe("Validation page", function() {

  before( function() {
    casper.start("http://localhost:3001")
    .viewport( 1100, 900 )
    .on( 'page.error', function (msg, trace) {
      this.echo( 'Browser JS error: ' + msg, 'ERROR' );
    })
    .on('remote.message', function(msg) {
      this.echo('Debug: ' + msg);
    })
    .on('remote.alert', function(msg) {
      this.echo('Alert: ' + msg);
    })
    .thenOpen("http://localhost:3001/validation");
  });

  it("should have expected content", function() {
    "Validating a sample manifest".should.be.textInDOM;
    "#validation-form".should.be.inDOM;
  });

  it("should validate valid upload", function() {
    casper.page.uploadFile("#csv", "data/validation_valid.csv");
    casper.click("#validation-form > button", function() {
      this.waitUntilVisible("#validation-success")
      .then(function() {
        "#validation-success".should.contain.text("Valid");
        "#validation-error".should.not.be.visible;
      });
    });
  });

  it("should show error for invalid upload", function() {
    casper.page.uploadFile("#csv", "data/validation_broken.csv");
    casper.click("#validation-form > button", function() {
      this.waitUntilVisible("#validation-error")
      .then(function() {
        "#validation-success".should.not.be.visible;
        "#validation-error".should.contain.text("Invalid");
      });
    });
  });

});

