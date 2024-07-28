SRC_DIR=lua

.PHONY: lint format all

all: lint format

lint: 
	luacheck ${SRC_DIR} 

format:
	stylua ${SRC_DIR} --config-path=.stylua.toml

