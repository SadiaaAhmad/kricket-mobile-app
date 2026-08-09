const http = require('https');

http.get('https://kricket.pk/assets/index-tvSvruUO.js', (resp) => {
  let d = '';
  resp.on('data', c => d += c);
  resp.on('end', () => {
    console.log('Total length:', d.length);
    
    // Search for image/player/logo/upload references in JS code
    const regex = /(?:image|img|logo|upload|photo|avatar|player)[^"'\n]{0,80}/gi;
    const matches = d.match(regex) || [];
    console.log('Sample matches (first 30):');
    const unique = Array.from(new Set(matches));
    console.log(unique.slice(0, 30));
  });
});
