run: run-backend

run-backend: build-frontend
	cd backend && \
		cargo run

build-frontend: backend/static/data.json
	cd frontend && \
		elm make src/Main.elm --output=../backend/static/main.js

backend/static/data.json: backend/static/font.json backend/static/textures.json backend/gen.py
	echo Building "data.json"...
	cd backend/static && \
		python ../gen.py

backend/static/font.json: sdf-render/charset.txt sdf-render/*.py sdf-render/Ubuntu-R.ttf
	echo Building font...
	cd sdf-render && \
		msdf-bmfont -t sdf -o Ubuntu-R.png -f json --pot -s 128  Ubuntu-R.ttf -r 16 -i charset.txt && \
		python correct_json.py && \
		python find_inside_point.py && \
		python flip.py && \
		mv Ubuntu-R.json ../backend/static/font.json && \
		mv Ubuntu-R.png ../backend/static/font.png

backend/static/textures.json: textures/png/* textures/*.py
	echo Building textures...
	cd textures && \
		python gen.py && \
		python flip.py && \
		mv textures.png ../backend/static/textures.png && \
		mv textures.json ../backend/static/textures.json

clean:
	cd backend/static/ && \
		rm data.json font.json textures.json font.png textures.png main.js