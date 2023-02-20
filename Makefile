
kr:
	mkdocs build --config-file docs/kr.yml

krserve:
	mkdocs serve --config-file docs/kr.yml

# en:
#	 mkdocs build --config-file md/en/mkdocs.yml

docs: kr

build:
	rojo build default.project.json -o output.rbxmx

all: build docs
