all: runScript

#Inserir o botTOKEN
bot_id=""

me_info:
	curl -s https://api.telegram.org/bot${bot_id}/getMe	

update_get:
	curl -s https://api.telegram.org/bot${bot_id}/getUpdates

git_push:
	git add .
	git commit -m "small change"
	git push -u source main

runPy:
	python3 cerebro.py 10 oi

runScript:
	bash script_main.sh ${bot_id}