.PHONY: deploy clean preview

deploy: clean build
	cp -pr ./_site/* ../

# clean: gh-pages
clean:
	./gh-pages clean

preview: deploy
	open ../index.html

# build: gh-pages
build:
	./gh-pages build

gh-pages: gh-pages.hs
	ghc --make -Wall gh-pages.hs
