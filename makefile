build-local:
	cp .env.example.local .env; flutter clean; flutter build apk

build-dev:
	cp .env.example.dev .env; flutter clean; flutter build apk