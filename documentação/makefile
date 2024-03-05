#Script para transformar o arquivo noweb em arquivo .tex e converte-lo para PDF
all:  make_latex get_script 

bot_id=6194010871:AAHkAo9WW2rhwWhJO9EZfTEkc-Mbl_se1g4
me_info:
	curl -s https://api.telegram.org/bot$(bot_id)/getMe	

update_get:
	curl -s https://api.telegram.org/bot$(bot_id)/getUpdates

make_latex:
	noweave main.nw > main.tex
	latex main.tex
	dvipdf main.dvi

get_script:
	notangle main.nw > script_main.sh

download_packages: 
	sudo apt update
	sudo apt install jq
	sudo apt install wget