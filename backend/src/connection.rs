use actix::{prelude::*, Actor, StreamHandler};
use actix_web_actors::ws;
use crate::{lobby::Lobby, messages::{FromPlayer, ToPlayer, ToServer}};

#[derive(Debug)]
pub struct PlayerConnection {
    lobby_addr: Addr<Lobby>,
}

impl PlayerConnection {
    pub fn new(lobby_addr: Addr<Lobby>) -> Self {
        Self {
            lobby_addr,
        }
    }
}

impl Actor for PlayerConnection {
    type Context = ws::WebsocketContext<Self>;
}

impl StreamHandler<ws::Message, ws::ProtocolError> for PlayerConnection {
    fn started(&mut self, ctx: &mut Self::Context) {
        self.lobby_addr.do_send(ToServer::StartSpectating(ctx.address().clone()));
    }

    fn finished(&mut self, ctx: &mut Self::Context) {
        self.lobby_addr.do_send(ToServer::StopSpectating(ctx.address().clone()));
    }

    fn handle(&mut self, msg: ws::Message, ctx: &mut Self::Context) {
        match msg {
            ws::Message::Ping(msg) => ctx.pong(&msg),
            ws::Message::Text(text) => {
                println!("server received text: {}", text);
                if let Ok(message) = serde_json::from_str::<FromPlayer>(&text) {
                    self.lobby_addr.do_send(ToServer::PlayerMessage(ctx.address().clone(), message));
                }
            },
            _ => (),
        }
    }
}

impl Handler<ToPlayer> for PlayerConnection {
    type Result = ();

    fn handle(&mut self, msg: ToPlayer, ctx: &mut Self::Context) {
        let text = serde_json::to_string(&msg).unwrap();
        println!("server sent text: {}", text);
        ctx.text(text);
    }
}
