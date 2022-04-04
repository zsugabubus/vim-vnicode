datadir ?= data

export datadir

update :
	$(MAKE) clean
	$(MAKE) all
	$(MAKE) xz

all : ga gA
ga : UnicodeData.txt NameAliases.txt
gA : NamesList.txt
%.txt : | $(datadir)
	test -f $(datadir)/$@* || \
	curl -Lo $(datadir)/$@ https://www.unicode.org/Public/UCD/latest/ucd/$@

$(datadir) :
	mkdir $@

gzip :
	gzip $(datadir)/*.txt
xz :
	xz $(datadir)/*.txt

clean :
	rm -f $(datadir)/*.txt*

.PHONY : update all ga gA gzip xz clean
