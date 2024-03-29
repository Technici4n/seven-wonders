// Init Elm app
let app = Elm.Main.init({
    node: document.getElementById('elm')
});

// WEBSOCKET HANDLING
const SERVER_ADDRESS = `ws://${window.location.hostname}:${window.location.port}/ws`;
let socket = new WebSocket(SERVER_ADDRESS);
let sendMessage = (message) => {
    socket.send(message);
}

app.ports.send.subscribe(sendMessage);
socket.onmessage = (event) => {
    app.ports.listen.send(event.data);
};
