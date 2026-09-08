const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = Number(process.env.PORT) || 8080;
const publicDir = path.join(__dirname, 'public');
const downloadsDir = path.join(__dirname, 'downloads');

function sendDownload(res, filePath, contentType, filename) {
  if (!fs.existsSync(filePath)) {
    res.status(404).type('text/plain').send('Archivo no disponible en este despliegue.');
    return;
  }
  res.setHeader('Content-Type', contentType);
  res.setHeader('Content-Disposition', 'attachment; filename="' + filename + '"');
  res.setHeader('Cache-Control', 'public, max-age=3600');
  res.sendFile(filePath);
}

app.get('/downloads/naves-arcade.apk', (req, res) => {
  sendDownload(
    res,
    path.join(downloadsDir, 'naves-arcade.apk'),
    'application/vnd.android.package-archive',
    'naves-arcade.apk',
  );
});

app.get('/downloads/naves-arcade-android.zip', (req, res) => {
  sendDownload(
    res,
    path.join(downloadsDir, 'naves-arcade-android.zip'),
    'application/zip',
    'naves-arcade-android.zip',
  );
});

app.get('/downloads/naves-arcade-ios.zip', (req, res) => {
  sendDownload(
    res,
    path.join(downloadsDir, 'naves-arcade-ios.zip'),
    'application/zip',
    'naves-arcade-ios.zip',
  );
});

app.use(express.static(publicDir, { index: 'index.html' }));

app.get('*', (req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('naves-arcade listening on 0.0.0.0:' + PORT);
});
