#!/bin/bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <ace-stream-pid>" >&2
	exit 1
fi

HASH="$1"
DIRNAME=$(cd "$(dirname "$0")" && pwd)
CONTAINER_NAME="${ACESTREAM_CONTAINER:-acestream-server}"
SERVER_HTTP_PORT="${ACESTREAM_PORT:-6878}"
DOCKER_IMAGE="${ACESTREAM_IMAGE:-magnetikonline/acestream-server:3.1.49_debian_8.11}"
PLAYER="${PLAYER:-vlc}"

started_container=0
log_tmp=$(mktemp)

cleanup() {
	rm -f "$log_tmp"
	if [[ "$started_container" == "1" ]]; then
		echo "Stopping container $CONTAINER_NAME..."
		docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
	fi
}
trap cleanup EXIT INT TERM

if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
	echo "Container $CONTAINER_NAME already running — reusing it."
else
	echo "Starting container $CONTAINER_NAME (image: $DOCKER_IMAGE)..."
	docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
	docker run --rm -d \
		--publish "$SERVER_HTTP_PORT:$SERVER_HTTP_PORT" \
		--tmpfs "/dev/disk/by-id:noexec,rw,size=4k" \
		--name "$CONTAINER_NAME" \
		"$DOCKER_IMAGE" >/dev/null
	started_container=1

	printf "Waiting for AceStream API"
	for _ in $(seq 1 30); do
		if curl -fs --max-time 1 "http://127.0.0.1:$SERVER_HTTP_PORT/webui/api/service?method=get_version" >/dev/null 2>&1; then
			echo " ready."
			break
		fi
		printf "."
		sleep 1
	done
fi

set +e
"$DIRNAME/playstream.py" --ace-stream-pid "$HASH" --port "$SERVER_HTTP_PORT" | tee "$log_tmp"
set -e

url=$(sed -nE 's/.*Playback available at \[(.*)\].*/\1/p' "$log_tmp" | tail -1)
if [[ -z "$url" ]]; then
	echo "Error: failed to obtain playback URL." >&2
	exit 1
fi

echo "Launching $PLAYER..."
"$PLAYER" "$url"
