const basicAuth = require('express-basic-auth')
const fs = require('fs');

module.exports = {
    "transpileDependencies": [
	"vuetify"
  ],
    devServer: {
      proxy: 'http://localhost:8083',
      public: process.env.ROBOPHONE_PUBLIC_URL,
      before(app, server, compiler) {
	  var users = {};
	  users[process.env.ROBOPHONE_USERNAME] = process.env.ROBOPHONE_PASSWORD;

          app.use(basicAuth({users: users,
			     challenge: true,
			     realm: 'robophone',
			    }));
      },
	https: process.env.ROBOPHONE_SSL_PATH ? 
	    {
		key: fs.readFileSync(process.env.ROBOPHONE_SSL_PATH + '/privkey.pem'),
		cert: fs.readFileSync(process.env.ROBOPHONE_SSL_PATH + '/fullchain.pem'),
		ca: fs.readFileSync(process.env.ROBOPHONE_SSL_PATH + '/chain.pem'),
	    } : 
	true,
  }
}
