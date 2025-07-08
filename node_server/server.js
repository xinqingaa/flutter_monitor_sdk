const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');

const app = express();
const port = 3000;

app.use(cors());
app.use(bodyParser.json({ limit: '10mb' })); // Increase limit for potentially large reports

app.post('/report', (req, res) => {
  console.log('--- ✅ Received Report ---');
  console.log('Timestamp:', new Date().toISOString());
  console.log('Body:', JSON.stringify(req.body, null, 2));
  console.log('-----------------------\n');
  
  res.status(200).send({ message: 'Report received' });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Mock server listening on all network interfaces at http://localhost:${port}`);
});
