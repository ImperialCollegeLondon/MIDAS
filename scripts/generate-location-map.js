const lines = `GAZ:00000892	Lima Region
GAZ:00002641	England
GAZ:00003623	Dublin City
GAZ:00003664	City of Cardiff
GAZ:00003672	London
GAZ:00003679	City of Newcastle Upon Tyne
GAZ:00003683	Manchester
GAZ:00003692	East Region
GAZ:00004832	Cambridge
GAZ:00004935	Belfast City
GAZ:00007597	City of Bangor
GAZ:00007611	Truro
GAZ:00010239	Cork
GAZ:00010709	Chachoengsao Province
GAZ:00052029	Bristol
GAZ:00052038	Southampton
GAZ:00052047	Bury Saint Edmunds
GAZ:00052099	Glasgow
GAZ:00052157	Leicester
GAZ:00281547	Brittish Isles
GAZ:00443620	Chelmsford
GAZ:00444167	Addenbrooke's Hospital
GAZ:00490568	Ashford
GAZ:00493993	Barnstaple
GAZ:00498389	Coventry
GAZ:00498481	Birmingham
GAZ:00499910	Shrewsbury`;

var request = require('sync-request');

function locationNameToLatLng(name) {
  const res = request('GET', `https://maps.googleapis.com/maps/api/geocode/json?&address=${name}`);
  const json = JSON.parse(res.getBody('utf8'));
  if (json.status === 'ZERO_RESULTS' || json.results.length === 0) {
    console.error('No location for', name);
    return { latitude: '', longitude: '' };
  }
  return {
    latitude: json.results[0].geometry.location.lat,
    longitude: json.results[0].geometry.location.lng,
  };
}

const locations = lines.split('\n').map(line => line.split('\t')).map(([id, name]) => {
  const { latitude, longitude } = locationNameToLatLng(name);
  return { id, name, latitude, longitude };
});

const dictionary = locations.reduce((dict, { id, name, latitude, longitude }) => {
  dict[id] = { name, latitude, longitude };
  return dict;
}, {});

console.log(`GAZ_LOCATIONS = ${JSON.stringify(dictionary)};`);
