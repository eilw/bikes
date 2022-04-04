import './main.css';
import {Elm} from './Main.elm';

const app = Elm.Main.init({
    node: document.getElementById('root')
});

let ui;

app.ports.initialiseMapPort.subscribe(() => {
    const platform = new H.service.Platform({
        'apikey': 'YnZdWvqVjCXyMcjIaunm4aibWuUJg4v49sFSHVNXGPY'
    });

    const defaultLayers = platform.createDefaultLayers();
    const map = initialiseMap(defaultLayers);

    app.ports.addStationsDetailsToMap.subscribe((stationsDetails) => {
        const group = setUpGroup(map);
        stationsDetails.forEach((station) =>
            addMarkerToGroup(group, {lat: station.latitude, lng: station.longitude},
                stationInfoHtml(station)
            )
        );
    })

    app.ports.addStationsToMap.subscribe((stations) => {
        const group = setUpGroup(map);
        stations.forEach((station) =>
            addMarkerToGroup(group, {lat: station.latitude, lng: station.longitude},
                stationNameHtml(station)
            )
        );
    })
});

function initialiseMap(defaultLayers) {
    const osloCoordinates = {lat: 59.93, lng: 10.75};

    const map = new H.Map(document.getElementById('mapContainer'),
        defaultLayers.vector.normal.map,
        {
            center: osloCoordinates,
            zoom: 13,
            pixelRatio: window.devicePixelRatio || 1
        }
    );
    // add a resize listener to make sure that the map occupies the whole container
    window.addEventListener('resize', () => map.getViewPort().resize());
     // Behavior implements default interactions for pan/zoom (also on mobile touch environments)
    const behavior = new H.mapevents.Behavior(new H.mapevents.MapEvents(map));

    // create default UI with layers provided by the platform
    ui = H.ui.UI.createDefault(map, defaultLayers);
    return map;
}

function setUpGroup(map) {
    const group = new H.map.Group();
    map.addObject(group);

    // add 'tap' event listener, that opens info bubble, to the group
    group.addEventListener('tap', (evt) => {
        // event target is the marker itself, group is a parent event target
        // for all objects that it contains
        const bubble = new H.ui.InfoBubble(evt.target.getGeometry(), {
            content: evt.target.getData()
        });
        ui.addBubble(bubble);
    }, false);

    return group;
}

function stationInfoHtml(station) {
    return stationNameHtml(station) +
        `<div>Sykler: ${station.numBikesAvailable}</div>` +
        `<div>Ledige plasser: ${station.numDocksAvailable}</div>`;
}

function stationNameHtml(station) {
    return `<div style="font-weight: bold">${station.name}</div>`;
}

function addMarkerToGroup(group, coordinate, html) {
    const marker = new H.map.Marker(coordinate);
    marker.setData(html);
    group.addObject(marker);
}
