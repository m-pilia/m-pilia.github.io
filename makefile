build:
	rm -rf _site/*
	bundle exec jekyll build
	cp CNAME _site/CNAME

serve:
	bundle exec jekyll serve
