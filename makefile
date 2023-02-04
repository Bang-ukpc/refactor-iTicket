build-local:
	export VERSION=$(version); cp .env.example.local .env; flutter clean; flutter build apk 

build-dev:
	export VERSION=$(version); cp .env.example.dev .env; flutter clean; flutter build apk

build-product:
	export VERSION=$(version); cp .env.example.product .env; flutter clean; flutter build apk

run:
	export VERSION=$(version); flutter run 