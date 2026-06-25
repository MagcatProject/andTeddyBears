export PROJECT := $(shell pwd)
export TYPE := ace
datafiles := $(patsubst YAML/%.yaml,Data/%.rvdata2,$(wildcard YAML/*.yaml))
yamlfiles := $(patsubst Data/%.rvdata2,YAML/%.yaml,$(wildcard Data/*.rvdata2))

.PHONY: unpack pack clean-yaml clean-data

unpack: $(yamlfiles)

pack: $(datafiles)

ifeq ($(firstword $(MAKECMDGOALS)),pack)
$(datafiles): Data/%.rvdata2: YAML/%.yaml
	rvpacker --verbose -d $(PROJECT) -t $(TYPE) -a pack -D $*
endif

ifeq ($(firstword $(MAKECMDGOALS)),unpack)
$(yamlfiles): YAML/%.yaml : Data/%.rvdata2
	rvpacker --verbose --force -d $(PROJECT) -t $(TYPE) -a unpack -D $*
endif

clean-yaml:
	rm -f YAML/*

clean-data:
	rm -f Data/*
