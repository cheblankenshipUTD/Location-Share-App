// general setup
// startPath, endPath, meetId is defined in ejs file.
let map;                    // google map
let marker;                 // marker of the user (client)
let directionsService;      // api that calculates route
let currentPath;            // current route on the map
let newPath;                // new route calculated
let mqttLatitudeData;       // mqtt latitude data. Use for checking if geolocation changes.
let mqttLongitudeData       // mqtt longitude data. Use for checking if geolocation changes.


// user setup
let userPosition;           // the geolocation of the user (client)

// sender setup
let senderStartLocation;    // senders initial start geo-location (get it via url param).
let senderEndLocation;      // senders initial end geo-location (get it via url param).
let senderCurrentLocation;  // senders current geo-location from mqtt msg.
let senderNewLocation;      // senders new geo-location (compare with current and update if its a new co-cordinate).
let senderMarker;           // this will be the marker for displaying the senders current location.



// *********** socket.io *********** //
var socket = io();

// Connect to socket.io
socket.on('connect', function(){
    console.log("connect to socket io");
});

// Get socket msg from specific event.
socket.on(meetId, function(data){
    var parsedMsgData = JSON.parse(data["msg"]); // access mqtt message property
    var coordinates = JSON.parse(parsedMsgData); // convert string into json farmat
    mqttLatitudeData = coordinates["lat"];
    mqttLongitudeData = coordinates["lng"];
    // update the sender positions
    if((senderCurrentLocation == null) || (senderCurrentLocation == undefined)) {
        senderCurrentLocation = new google.maps.LatLng(mqttLatitudeData, mqttLongitudeData);
    }
    senderNewLocation = new google.maps.LatLng(mqttLatitudeData, mqttLongitudeData);

});

// Disconnect from socket.io
// socket.on('disconnect', function(){});

// *********************************** //

function initMap() {

    // initialize directions service and renderer library.
    directionsService = new google.maps.DirectionsService();

    // initialize map object.
    map = new google.maps.Map(document.getElementById("map"), {
        // set center to users geolocation (`user` is who is opening the browser).
        center: new google.maps.LatLng(startPath["x"], startPath["y"]), // default geo-coordinate
        zoom: 15,
        mapTypeId:'roadmap',
        disableDefaultUI: true
    });

    // HTML5 geolocation (get clients current location).
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
            (position) => {
                // get user location (`user` is who is opening the browser).
                userPosition = new google.maps.LatLng(position.coords.latitude, position.coords.longitude);
                // set it to users center only when btn clocked.
                map.setCenter(userPosition);

                //initialize marker (client marker).
                marker = new google.maps.Marker({
                    map,
                    draggable: true,
                    position: userPosition,
                    icon: {
                        path: google.maps.SymbolPath.CIRCLE,
                        scale: 10,
                        fillOpacity: 1,
                        strokeWeight: 2,
                        fillColor: '#5384ED',
                        strokeColor: '#ffffff',
                    },
                });

                // initialize marker (sender).
                senderMarker = new google.maps.Marker({
                    map,
                    draggable: true,
                    position: new google.maps.LatLng(0, 0), // set to (0,0) for initial setup.
                    icon: {
                        path: google.maps.SymbolPath.CIRCLE,
                        scale: 10,
                        fillOpacity: 1,
                        strokeWeight: 2,
                        fillColor: '#000',
                        strokeColor: '#ffffff',
                    },
                });

            },
            () => {
                handleLocationError(true, infoWindow, map.getCenter());
            }
        );


        // calculate route
        // senderStartLocation = new google.maps.LatLng(33.001884, -96.764698);
        senderStartLocation = new google.maps.LatLng(startPath["x"], startPath["y"]);
        // senderEndLocation   = new google.maps.LatLng(32.994522, -96.750272);
        senderEndLocation   = new google.maps.LatLng(endPath["x"], endPath["y"]);

        //
        setInterval(function(){
            // if the senderCurrentLocation is null of undefined, set it eql to senderStartLocation.
            if((senderCurrentLocation == null) || (senderCurrentLocation == null)) {
                senderCurrentLocation = senderStartLocation;
            }
            // compare senderCurrentLocation and senderNewLocation.
            // Call calculateAndDisplayRoute() if the geo-location is changed.
            if(senderCurrentLocation != senderNewLocation) {
                console.log("compared current and new. lets update the location since its different!");
                console.log("current >> " + senderCurrentLocation);
                console.log("new >> " + senderNewLocation);
                calculateAndDisplayRoute(directionsService, senderNewLocation, senderEndLocation, google.maps.TravelMode.DRIVING);
            }
            else {
                console.log("same co-ordinate! dont update the path");
            }
        }, 3000);


    } else {
        // Browser doesn't support Geolocation
        handleLocationError(false, infoWindow, map.getCenter());
    }

}


function calculateAndDisplayRoute(directionsService, startPosition, endPosition, travelMode) {
    // call the directionsService.route() method.
    directionsService.route({
        origin: startPosition,
        destination: endPosition,
        travelMode: travelMode,
    },
    (response, status) => {
        if (status === "OK") {
            // console.log("Response >> " + JSON.stringify(currentPath));
            // if currentPath is undefined/null, set the path and draw it on the map.

            if(currentPath == null || currentPath == undefined) {
                console.log("Hey its NULLLLLL");
                currentPath = new google.maps.Polyline({
                    path: response["routes"][0]["overview_path"], // access the polyline from google map api returned JSON data.
                    strokeColor: "#4C8BF5",
                    strokeOpacity: 0.3,
                    strokeWeight: 3,
                });
                currentPath.setMap(map);
            }
            // If currentPath already exist, update the currentPath and newPath.
            else {
                console.log("<<update>>");
                // Set the new path
                newPath = new google.maps.Polyline({
                    path: response["routes"][0]["overview_path"], // access the polyline from google map api returned JSON data.
                    strokeColor: "#000",
                    strokeOpacity: 0.3,
                    strokeWeight: 3,
                });
                // route update
                newPath.setMap(map);
                currentPath.setMap(null);
                currentPath = newPath;

                // marker update
                senderMarker.setPosition(startPosition);
            }


        } else {
            window.alert("Directions request failed due to " + status);
        }
    });
}

function moveMarkerSmoothly(startPosition, endPosition) {

}


//// Error handling
function handleLocationError(browserHasGeolocation, infoWindow, userPosition) {
    infoWindow.setPosition(userPosition);
    infoWindow.setContent(
        browserHasGeolocation
        ? "Error: The Geolocation service failed."
        : "Error: Your browser doesn't support geolocation."
    );
    infoWindow.open(map);
}
