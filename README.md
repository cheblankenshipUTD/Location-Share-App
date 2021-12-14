# Location Share App

## Description
Web/iOS app that optimize individual meetups
This is the client-side application. When the user(sender) sets their destination, traveling mode, and contact info, the information will be send via text message to the client. When the client opens up the url, it will start subscribe to the specific uuid topic mqtt messages.
The sender-side(iOS app) will keep updating the gps current location every 5-10ft change.
Using the Google Map JavaScript Library, it can get the estimated time arrival. In addition, when the route changes, it will automatically update on the web app side so the client can know exactly where, how, when the sender arrives.


## Architecture Overview
<img src="https://github.com/PugNorange/Meetup-Optimization/blob/main/documentation/architecture_overview.png" width="500" height="600">

## URL style
hostname/`sesstion id`/`start gps x-coordinate`/`start gps y-coordinate`/`end gps x-coordinate`/`end gps y-coordinate`

`sesstion id` ... uuid

`gps coordinates` ... integer

[Example]: http://localhost:3000/318c2f44-5d97-449e-8aef-416757103f10/33.001884/-96.764698/32.994522/-96.750272


## iOS app images
<p float="left">
<img src="https://github.com/PugNorange/Meetup-Optimization/blob/main/documentation/ios_screenshot1.png" width="270" height="480">
<img src="https://github.com/PugNorange/Meetup-Optimization/blob/main/documentation/ios_screenshot2.png" width="270" height="480">

<img src="https://github.com/PugNorange/Meetup-Optimization/blob/main/documentation/ios_screenshot3.png" width="270" height="480">
<img src="https://github.com/PugNorange/Meetup-Optimization/blob/main/documentation/ios_screenshot4.png" width="270" height="480">
</p>


## Web app images
<img src="https://github.com/PugNorange/Meetup-Optimization/blob/main/documentation/web_screenshot1.png" width="370" height="480">
