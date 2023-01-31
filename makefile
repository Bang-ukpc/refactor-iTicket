build-local:
	cp .env.example.local .env; flutter clean; flutter build apk

build-dev:
	cp .env.example.dev .env; flutter clean; flutter build apk

build-product:
	cp .env.example.product .env; flutter clean; flutter build apk