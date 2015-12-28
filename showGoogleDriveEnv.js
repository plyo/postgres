const fs = require('fs');
const readline = require('readline');
const google = require('googleapis');
const googleAuth = require('google-auth-library');

const SCOPES = [
  // needed to list folders
  'https://www.googleapis.com/auth/drive.metadata',
  // needed to create files
  'https://www.googleapis.com/auth/drive.file'
];

const credentials = require('./client_secret.json');
const clientSecret = credentials.installed.client_secret;
const clientId = credentials.installed.client_id;
const redirectUrl = credentials.installed.redirect_uris[0];
const auth = new googleAuth();
const oauth2Client = new auth.OAuth2(clientId, clientSecret, redirectUrl);

const authUrl = oauth2Client.generateAuthUrl({
  access_type: 'offline',
  scope: SCOPES
});

console.log('Authorize this app by visiting this url: ', authUrl);
var rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

rl.question('Enter the code from that page here: ', function(code) {
  rl.close();
  oauth2Client.getToken(code, function(err, token) {
    if (err) {
      console.log('Error while trying to retrieve access token', err);
      return;
    }

    console.log(`Your env variables:
    - CLIENT_ID=${clientId}
    - CLIENT_SECRET=${clientSecret}
    - ACCESS_TOKEN=${token.access_token}
    - REFRESH_TOKEN=${token.refresh_token}
    - EXPIRY_DATE=${token.expiry_date}
    `);
  });
});

