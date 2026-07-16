declare module "phoenix_html";

declare module "phoenix" {
  export class Socket {
    constructor(endpoint: string, options?: Record<string, unknown>);
  }
}

declare module "phoenix_live_view" {
  import type { Socket } from "phoenix";

  export interface LiveSocketOptions {
    longPollFallbackMs?: number;
    params?: Record<string, unknown>;
  }

  export class LiveSocket {
    constructor(endpoint: string, socket: typeof Socket, options?: LiveSocketOptions);
    connect(): void;
  }
}
