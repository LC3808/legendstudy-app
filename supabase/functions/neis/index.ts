import { createHandler } from "./handler.ts";
Deno.serve(createHandler(() => Deno.env.get("NEIS_API_KEY")));
