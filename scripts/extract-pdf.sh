#!/bin/bash
# Use pdftk or poppler-utils to extract part of PDF to OUTPUT
# pdftk is recommended which will produce a smaller size OUTPUT
# Ver 1.4.20221010
# #################################################################
# Just use
# $ qpdf --empty --pages input.pdf 1-10 -- output.pdf
# OR
# $ qpdf input.pdf --pages . 1-10 -- output.pdf
# More ways: https://askubuntu.com/questions/221962/how-can-i-extract-a-page-range-a-part-of-a-pdf
# Ignore below useless code  :-(
# #################################################################
PDF=$1
OUTPUT=$2
START=$3
END=$4
[ ! -f "$PDF" -o -z "$START" ] && echo "Syntax: $0 input_pdf output_pdf start_page [end_page]" && exit 0
cat /dev/null >$OUTPUT 2>/dev/null
[ $? != 0 ] && echo "Error: Not able to write $OUTPUT" && exit 5

getPages() {
	# Related Package
	# exiftool: libimage-exiftool-perl, pdfinfo: poppler-utils
	local p=$1
	[ -n "$(type -P pdfinfo)" ] && pdfinfo $p | awk '/^Pages:/ {print $2}' && return $?
	[ -z "$(type -P exiftool)" ] && echo "Error: Please install either libimage-exiftool-perl or poppler-utils first." && exit 2
	exiftool -T -filename -PageCount -s3 -ext pdf $p | awk '{print $2}'
	# There is one more way to get pagecount easily: $ qpdf --show-npages $filename
}

extract() {
	# Related Package
	# pdftk: pdftk, pdfseprate + pdfunite: poppler-utils
	[ -n "$(type -P pdftk)" ] && pdftk $PDF cat ${START}-${END} output $OUTPUT && return $?
	# The other way to use poppler-utils package to extract pages, sepate into multiple sigle-page pdfs then merge
	[ -z "$(type -P pdfinfo)" ] && echo "Error: Please install either pdftk or poppler-utils first." && exit 3
	pdfseparate -f $START -l $END $PDF /tmp/pdf-$$-%d.pdf
	pdfunite $(ls /tmp/pdf-$$-*.pdf | xargs) $OUTPUT
	rm /tmp/pdf-$$-*.pdf
	return $?
}

# Main Prog.
pCount=$(getPages $PDF)
[ -z "$END" ] && END=$pCount
[ -z "$END" ] && echo "Error: Not able to find page count of $PDF" && exit 6
[ $END -gt $pCount ] && echo "Error: end page number too big" && exit 7
[ $END -lt $START ] && echo "Error: end page number should big than or equal to start page number" && exit 8
echo "Extracting pages $START-$END into $OUTPUT ..."
COUNT=$((${END} - ${START} + 1))
extract
# Verify
[ "$COUNT" != "$(getPages $OUTPUT)" ] && echo "Error: $OUTPUT got wrong page count."
