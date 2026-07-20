import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { mountIncant } from "./incant";

const csrfToken = document.querySelector<HTMLMetaElement>("meta[name='csrf-token']")?.content;

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
});

mountIncant();

liveSocket.connect();
window.liveSocket = liveSocket;
