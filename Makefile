
kr:
	mkdocs build -f mkdocs_kr.yml
krserve:
	mkdocs serve -f mkdocs_kr.yml

en:
	mkdocs build -f mkdocs_en.yml
enserve:
	mkdocs serve -f mkdocs_en.yml

docs: kr en

build:
	rojo build default.project.json -o output.rbxmx

test:
	rojo serve test.project.json

all: build docs
