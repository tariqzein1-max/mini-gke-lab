const express = require('express');
const app = express();
const port = process.env.PORT || 8080;


app.get('/', (req, res) => {
res.send(`Hello from GKE Autopilot! Time: ${new Date().toISOString()}`);
});


app.get('/health', (req, res) => res.status(200).send('ok'));


app.listen(port, () => console.log(`Listening on ${port}`));