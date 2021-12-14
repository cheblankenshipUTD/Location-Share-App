const express   = require("express");
const app       = express();
const server    = require('http').createServer(app);
const path      = require("path");
const io        = require("socket.io")(server);
const mqtt      = require("mqtt");
const fs        = require("fs");
const rawdata   = fs.readFileSync("./data/keys.json");
const convData  = JSON.parse(rawdata);
const gKey      = convData["gmap-key"];
const port      = 3000;

// Test URL
// http://localhost:3000/318c2f44-5d97-449e-8aef-416757103f10/33.001884/-96.764698/32.994522/-96.750272

// *********** socket.io setup *********** //
// io.on("connection", function (socket) {
//     console.log("Made socket connection");
// });
let socketId = "318c2f44-5d97-449e-8aef-416757103f10";
io.on('connection', (socket) => {
    console.log('a user connected');
});
// *********************************** //


// *********** mqtt setup *********** //
// https://www.emqx.io/mqtt/public-mqtt5-broker
var mqttData;
var mqttClient = mqtt.connect('mqtt://broker.emqx.io');
mqttClient.on('connect', function () {
    mqttClient.subscribe('test/matta/318c2f44-5d97-449e-8aef-416757103f10', function (err) {
        if (!err) {
            console.log("subscribe successfully");
        } else {
            console.log("mqtt connection/subscribe error");
        }
    });
});

// Get all the mqtt messages.
// Send them with an event linked with meetID.
// Front end will only pick up the even (meetId) thats provided to them.
// subscribe to the mqtt topic using the meetId.
// send the data via socket using the meetId.
mqttClient.on('message', function (topic, message) {
    // message is Buffer
    console.log("topic    : " + topic.toString());
    console.log("msg      : " + message.toString());
    mqttData = {
        "topic": topic.toString(),
        "msg": message.toString()
    }

    io.emit(socketId ,mqttData);
    // client.end()
});
// *********************************** //

// set static
app.use(express.static("public"));
app.use("/css", express.static(__dirname + "public/css"));
app.use("/js", express.static(__dirname + "public/js"));
app.use("/img", express.static(__dirname + "public/img"));

// set the view engine to ejs
app.set("views", "./views");
app.set("view engine", "ejs");

// main page
app.get('/:meetId/:startX/:startY/:endX/:endY', function(req, res) {
    var meetId  = req.param("meetId");
    var startX  = req.param("startX");
    var startY  = req.param("startY");
    var endX    = req.param("endX");
    var endY    = req.param("endY");
    // render the main page
    res.render("index",{
        title: "Matta",
        meetId: meetId,
        gKey: gKey,
        startCoordinate: {
            x: startX,
            y: startY
        },
        endCoordinate: {
            x: endX,
            y: endY
        }
    });

});

server.listen(port, () => {
  console.log(`Example app listening at http://localhost:${port}`)
})
