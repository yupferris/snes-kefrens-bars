PROJECT=snes-kefrens-bars
DEMO=$(PROJECT).sfc
SOURCE=$(PROJECT).asm
OBJ=$(PROJECT).obj
LINKSCRIPT=$(PROJECT).link

TAB=tab.bin

SINTABGENDIR=sintab

ASM=wla-65816
LINK=wlalink

EMU=higan
EMUFLAGS=

RM=rm
RMFLAGS=-f

all: $(DEMO)

$(DEMO): $(OBJ) $(LINKSCRIPT)
	$(LINK) $(LINKSCRIPT) $(DEMO)

$(OBJ): $(SOURCE) $(TAB)
	$(ASM) -o $(OBJ) $(SOURCE)

$(TAB): sintabgen
	cd $(SINTABGENDIR) && cargo run -- $(CURDIR)/$(TAB)

sintabgen:
	cd $(SINTABGENDIR) && cargo build

test: $(DEMO)
	$(EMU) $(EMUFLAGS) $(DEMO)

clean:
	$(RM) $(RMFLAGS) $(DEMO) $(OBJ)
