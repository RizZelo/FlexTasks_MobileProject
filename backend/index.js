const express = require('express');
const app = express();
const cors = require('cors');
const axios = require('axios');

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: "Hello from Express backend!" });
});

// OpenStreetMap Nominatim Places Search endpoint (FREE - No API key needed)
app.get('/api/places/autocomplete', async (req, res) => {
  try {
    const { input } = req.query;
    
    if (!input) {
      return res.status(400).json({ error: 'Input parameter is required' });
    }

    // Using OpenStreetMap Nominatim API (free geocoding service)
    const response = await axios.get(
      'https://nominatim.openstreetmap.org/search',
      {
        params: {
          q: input,
          format: 'json',
          addressdetails: 1,
          limit: 5,
          countrycodes: 'us,ca,gb,fr,de' // Adjust countries as needed
        },
        headers: {
          'User-Agent': 'FlexTasksApp/1.0' // Required by Nominatim
        }
      }
    );

    // Transform Nominatim response to match expected format
    const predictions = response.data.map(place => ({
      description: place.display_name,
      place_id: place.place_id.toString(),
      lat: parseFloat(place.lat),
      lon: parseFloat(place.lon),
      name: place.name || place.display_name.split(',')[0],
      address: place.display_name
    }));

    res.json({
      status: 'OK',
      predictions: predictions
    });
  } catch (error) {
    console.error('Error fetching places:', error.message);
    res.status(500).json({ 
      error: 'Failed to fetch places',
      details: error.message 
    });
  }
});

// Get place details endpoint (using Nominatim reverse geocoding)
app.get('/api/places/details', async (req, res) => {
  try {
    const { place_id, lat, lon } = req.query;
    
    if (!place_id && (!lat || !lon)) {
      return res.status(400).json({ error: 'Place ID or coordinates required' });
    }

    let url = 'https://nominatim.openstreetmap.org/lookup';
    let params = {
      format: 'json',
      addressdetails: 1
    };

    if (place_id) {
      params.osm_ids = `N${place_id}`; // N for node, can be R for relation or W for way
    }

    const response = await axios.get(url, {
      params: params,
      headers: {
        'User-Agent': 'FlexTasksApp/1.0'
      }
    });

    if (response.data && response.data.length > 0) {
      const place = response.data[0];
      res.json({
        status: 'OK',
        result: {
          name: place.name || place.display_name.split(',')[0],
          formatted_address: place.display_name,
          place_id: place.place_id.toString(),
          geometry: {
            location: {
              lat: parseFloat(place.lat),
              lng: parseFloat(place.lon)
            }
          }
        }
      });
    } else {
      res.status(404).json({ error: 'Place not found' });
    }
  } catch (error) {
    console.error('Error fetching place details:', error.message);
    res.status(500).json({ 
      error: 'Failed to fetch place details',
      details: error.message 
    });
  }
});

app.listen(3000, () => console.log("Server running on port 3000"));
