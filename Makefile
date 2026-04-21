simulate-ci:
	docker build -t docker-brasfoot  .
	docker run --rm \
		--name=brasfoot \
		-e PUID=1000 \
		-e PGID=1000 \
		-e TZ=America/Sao_Paulo \
		-p 3000:3000 \
		--shm-size="2gb" \
		docker-brasfoot

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
		--shm-size="2gb" \
		docker-brasfoot