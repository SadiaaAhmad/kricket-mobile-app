const http = require('https');

http.get('https://kricket.pk/assets/index-tvSvruUO.js', (resp) => {
  let d = '';
  resp.on('data', c => d += c);
  resp.on('end', () => {
    const idx = d.indexOf('players/P');
    if (idx !== -1) {
      console.log('--- Found players/P ---');
      console.log(d.substring(idx - 200, idx + 400));
    }
    
    const idx2 = d.indexOf('player.png');
    if (idx2 !== -1) {
      console.log('--- Found player.png ---');
      console.log(d.substring(idx2 - 200, idx2 + 400));
    }
  });
});
