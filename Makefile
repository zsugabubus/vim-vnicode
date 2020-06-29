all : ga gA

ga : UnicodeData.txt NameAliases.txt

gA : NamesList.txt

%.txt : | data
	test -f data/$@ || curl -Lo data/$@ https://www.unicode.org/Public/UCD/latest/ucd/$@

# Various compression methods.
gzip :
	gzip data/*

xz :
	xz data/*

data :
	mkdir $@

.PHONY : all ga gA gzip xz
