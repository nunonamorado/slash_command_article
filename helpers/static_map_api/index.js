var proxy = require('express-http-proxy');
const express = require('express');
const app = express();

const port = process.env.PORT || 3000;
const mapbox_api_token = process.env.MAPBOX_API_TOKEN;
const mapbox_static_url = "https://api.mapbox.com/styles/v1/mapbox/streets-v11/static";


app.use('/staticmap', proxy("https://api.mapbox.com", {
  proxyReqPathResolver: function (req) {
    const lat = req.query.lat || "";
    const lon = req.query.lon || "";
    return `${mapbox_static_url}/${lon},${lat},13,0,0/512x288@2x?access_token=${mapbox_api_token}`;
  }
}));

app.listen(port, err => {
    if (err) throw err
    console.log(`> Ready On Server http://localhost:${port}`)
});
