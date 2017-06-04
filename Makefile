PROJECT=snes-kefrens-bars
DEMO=$(PROJECT).sfc
SOURCE=$(PROJECT).asm
OBJ=$(PROJECT).obj
LINKSCRIPT=$(PROJECT).link
ASM=wla-65816
LINK=wlalink
EMU=higan
EMUFLAGS=
RM=rm
RMFLAGS=-f

all: $(DEMO)

$(DEMO): $(OBJ) $(LINKSCRIPT)
	$(LINK) $(LINKSCRIPT) $(DEMO)

$(OBJ): $(SOURCE)
	$(ASM) -o $(OBJ) $(SOURCE)

test: $(DEMO)
	$(EMU) $(EMUFLAGS) $(DEMO)

clean:
	$(RM) $(RMFLAGS) $(DEMO) $(OBJ)
