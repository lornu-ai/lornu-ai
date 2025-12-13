
export interface Env {
	ASSETS: Fetcher;
}

export default {
	async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
		const response = await env.ASSETS.fetch(request);

		// Ensure content-type is set correctly
		const contentType = response.headers.get("Content-Type");
		if (!contentType) {
			// Basic MIME type inference fallback if ASSETS binding misses it
			const url = new URL(request.url);
			const path = url.pathname;
			let newHeaders = new Headers(response.headers);

			if (path.endsWith(".html")) {
				newHeaders.set("Content-Type", "text/html;charset=UTF-8");
			} else if (path.endsWith(".css")) {
				newHeaders.set("Content-Type", "text/css;charset=UTF-8");
			} else if (path.endsWith(".js")) {
				newHeaders.set("Content-Type", "application/javascript;charset=UTF-8");
			} else if (path.endsWith(".json")) {
				newHeaders.set("Content-Type", "application/json;charset=UTF-8");
			}

			return new Response(response.body, {
				status: response.status,
				statusText: response.statusText,
				headers: newHeaders,
			});
		}

		return response;
	},
};
