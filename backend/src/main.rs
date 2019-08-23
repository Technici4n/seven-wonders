use actix::prelude::*;
use actix_files as fs;
use actix_web::{web, App, HttpRequest, HttpServer, Responder};
use actix_web_actors::ws;
use std::io;
use crate::lobby::Lobby;

mod connection;
mod game;
mod lobby;
mod messages;

#[derive(Debug, Clone)]
struct AppState {
    lobby_addr: Addr<Lobby>,
}

fn main() -> io::Result<()> {
    // init runtime
    let sys = actix_rt::System::new("seven_wonders");

    // start actors
    let lobby_addr = Lobby::new().start();

    // init state
    let state = AppState {
        lobby_addr,
    };
    let data = web::Data::new(state);

    // start server
    let _server = HttpServer::new(move || {
        App::new()
            .register_data(data.clone())
            .route("/ws", web::get().to(websocket))
            .service(fs::Files::new("/", "static").show_files_listing())
    })
    .bind("0.0.0.0:8001")?.start();

    // start runtime
    sys.run().unwrap();

    Ok(())
}

fn websocket(req: HttpRequest, stream: web::Payload, data: web::Data<AppState>) -> impl Responder {
    let resp = ws::start(connection::PlayerConnection::new(data.lobby_addr.clone()), &req, stream);
    println!("{:?}", resp);
    resp
}