#!/bin/bash

echo "Pulling locale.gen.txt from etc/locale.gen"

if [ -e /etc/locale.gen ]
then
	echo "locale.gen found!"
	cp /etc/locale.gen locale.gen.txt
	echo "locale.gen copied into locale.gen.txt!"
	exit 0
else
	echo "Locale config copy: failed: /etc/locale.gen not found!"
	echo "Please manually edit 'locale.gen.txt' and enable required locales"
	exit 1
fi
