module.exports = function() {
  var server = process.server

  describe('logout', function() {
    it('should log out', function () {
      return server.logout('some-token')
               .status(200)
               .body_ok(/Logged out/)
    })
  })
}
