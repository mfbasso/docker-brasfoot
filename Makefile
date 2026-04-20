build:
	docker build -t docker-brasfoot  .

run:
	docker run --rm \
		--name=brasfoot \
		-e PUID=1000 \
		-e PGID=1000 \
		-e TZ=America/Sao_Paulo \
		-p 3000:3000 \
		-v ./data:/data \
		-v ./register:/config/.local/share/brasfoot \
		--shm-size="2gb" \
		docker-brasfoot