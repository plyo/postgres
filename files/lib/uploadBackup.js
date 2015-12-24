const fs = require('fs');
const path = require('path');
const google = require('googleapis');
const googleAuth = require('google-auth-library');

const googleAPICredentials = require('./google_api_credentials.json');
const clientSecret = googleAPICredentials.installed.client_secret;
const clientId = googleAPICredentials.installed.client_id;
const redirectUrl = googleAPICredentials.installed.redirect_uris[0];
const auth = new googleAuth();
const oauth2Client = new auth.OAuth2(clientId, clientSecret, redirectUrl);
oauth2Client.credentials = require('./google_oauth_credentials.json');

const filePath = process.argv[2];
const drive = google.drive({ version: 'v3', auth: oauth2Client });

console.log('Search `backups` folder on google drive');
drive.files.list({
  q: "name='backups' and mimeType = 'application/vnd.google-apps.folder'",
  fields: "nextPageToken, files(id, name)"
}, function(err, response) {
  if (err) {
    throw err;
  }

  if (!response.files || !response.files.length) {
    console.error('You must have `backups` directory in the root of your google drive');
    return;
  }

  console.log(`Uploading ${filePath}...`);
  drive.files.create({
    resource: {
      name: filePath,
      parents: [response.files[0].id],
      mimeType: 'application/x-gzip'
    },
    media: {
      mimeType: 'application/x-gzip',
      body: fs.createReadStream(path.join(__dirname, filePath))
    }
  }, function(err) {
    if (err) {
      console.log('Backup uploading failed');
      throw err;
    }

    console.log('Backup uploading complete successfully!');
  });

});
