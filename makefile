build-local:
	cp .env.example.local .env; flutter build apk

build-dev:
	cp .env.example.dev .env; flutter build apk