#!/bin/bash
botTOKEN=""
offset="0"
pipeline="$1"

default_msg="Ola estou na versao 1.0, sou o "
interaction_type=""
image_type=""

status_id=""
status_resid=""

function set_basic_config (){
        if [[ ${pipeline} != "" ]]; then
                botTOKEN=${pipeline}
        fi

        bot_info=`curl -s https://api.telegram.org/bot${botTOKEN}/getMe`
        name_bot="$(echo $bot_info | jq -r ".result.first_name")"
        default_msg=$default_msg""$name_bot
        
        script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
        if [ ! -f "${script_dir}/next_id.txt" ]; then
                touch "${script_dir}/next_id.txt"
                offset="0"
        else
                offset=`cat ${script_dir}/next_id.txt`
                if [ offset==" " ]; then
                        offset="0"
                fi
        fi
}

function config_usr_dir(){
        user_dir="${script_dir}/$user_id"
        mkdir -p ${user_dir}

        brain_dir="${script_dir}/brain"

        if [ ! -f "${user_dir}/doc_confirm.txt" ]; then
                touch "${user_dir}/doc_confirm.txt"
        fi

        if [ ! -f "${user_dir}/resid_confirm.txt" ]; then
                touch "${user_dir}/resid_confirm.txt"
        fi

        user_json_dir="${user_dir}/jsons"
        mkdir -p $user_json_dir

        user_imgs_dir="${user_dir}/imgs"
        mkdir -p $user_imgs_dir

        user_docs_dir="${user_dir}/docs"
        mkdir -p $user_docs_dir

        user_vid_dir="${user_dir}/vid"
        mkdir -p $user_vid_dir
}

function status_checklist_generate(){
        doc_conf=`cat ${user_dir}/doc_confirm.txt`
        resid_conf=`cat ${user_dir}/resid_confirm.txt`
        
        if [[ ${doc_conf} != "" ]]; then
                echo "DOCUMENTO"
        fi

        if [[ ${resid_conf} != "" ]]; then
                echo "RESIDENCIA"
        fi
}

function next_id_update(){
        offset="$((update_id + 1))"
        echo $offset > ${script_dir}/next_id.txt
}

function listen_usr(){
        while true 
        do
        #pega as mensagens que foram enviadas
        updates="$(curl -s "https://api.telegram.org/bot${botTOKEN}/getupdates?offset=${offset}")"

        result="$(echo $updates | jq -r ".result")"
        error="$(echo $updates | jq -r ".description")"

        if [[ "${result}" == "[]" ]]; then
                exit 0
        elif [[ "${error}" != "null" ]]; then
                echo "${error}" && exit 0
        fi

        timestamp="$(echo $result | jq -r ".[0].message.date")"

        define_msg_type
        next_id_update
        if [[ ${interaction_type} == "photo" ]]; then
                if [[ ${image_type} == 0 ]]; then
                        msg="A imagem enviada é um documento de identidade"
                elif [[ ${image_type} == 1 ]]; then
                        msg="A imagem enviada é um comprovante de residência"
                fi
                interaction_type=""
        fi
        send_message
        #export_csv

        done
}

function define_msg_type(){
        update_id="$(echo $result | jq -r ".[0].update_id")"
        user_id="$(echo $result | jq -r ".[0].message.chat.id")"

        config_usr_dir

        result_user="$(echo $result | jq -r ".[0]")"
        echo $result_user > result_user.json
        jq . result_user.json > ${user_json_dir}/$update_id.json
        rm result_user.json

        document_confirm="$(echo $result | jq -r ".[0].message.document")"
        photo_confirm="$(echo $result | jq -r ".[0].message.photo")"
        video_confirm="$(echo $result | jq -r ".[0].message.video")"
        voice_confirm="$(echo $result | jq -r ".[0].message.voice")"
        
        if [[ ${document_confirm}  != "null" ]]; then
                interaction_type="document"
                process_document
        elif [[ ${photo_confirm} != "null" ]]; then
                interaction_type="photo"
                process_photo
        elif [[ ${video_confirm} != "null" ]]; then
                interaction_type="video"
                process_video
        elif [[ ${voice_confirm} != "null" ]]; then
                interaction_type="voice"
                process_voice
        else
                interaction_type="text"
                process_text
        fi
}

function process_document(){
        file_id="$(echo $result | jq -r ".[0].message.document.file_id")"
        file_json=`curl -s https://api.telegram.org/bot${botTOKEN}/getFile?file_id=${file_id}`
        file_path="$(echo $file_json | jq -r ".result.file_path")"

        application="$(echo $file_path | cut -d "." -f2)"

        curl -s -o "${user_docs_dir}/${update_id}.${application}" "https://api.telegram.org/file/bot${botTOKEN}/${file_path}"

        msg="Recebemos o seu documento!"
}

function process_photo(){
        file_id="$(echo $result | jq -r ".[0].message.photo[-1].file_id")"
        file_json=`curl -s https://api.telegram.org/bot${botTOKEN}/getFile?file_id=${file_id}`
        file_path="$(echo $file_json | jq -r ".result.file_path")"
        
        application="$(echo $file_path | cut -d "." -f2)"

        curl -s -o "${user_imgs_dir}/${update_id}.${application}" "https://api.telegram.org/file/bot${botTOKEN}/${file_path}"
        tesseract $user_imgs_dir/${update_id}.${application} ${user_imgs_dir}/${update_id}

        msg=`cat "$user_imgs_dir/${update_id}.txt"`
        msg=`echo ${msg^^}`

        echo ${msg}
        if [[ $msg == *"NOME"* ]] && [[ $msg == *"CPF"* ]]; then
                image_type="0"
        fi

        if [[ ${msg} == " \n\ff" ]]; then
                msg="Não conseguimos detectar texto nesta imagem"
        fi
}

function process_video(){
        msg="por enquanto não estou processsando este tipo de mídia"
}

function process_voice(){
        msg="por enquanto não estou processsando este tipo de mídia"
}

function process_photo_dae(){
        while true
        do
                updates="$(curl -s "https://api.telegram.org/bot${botTOKEN}/getupdates?offset=${offset}")"

                if [[ "${stop}" == "1" ]]; then
                        break
                fi

                result="$(echo $updates | jq -r ".result")"
                error="$(echo $updates | jq -r ".description")"

                if [[ "${result}" != "[]" ]]; then
                        update_id="$(echo $result | jq -r ".[0].update_id")"
                        text_received="$(echo $result | jq -r ".[0].message.text")"
                        photo="$(echo $result | jq -r ".[0].message.photo[-1]")"
                        if [[ "${photo}" != "null" ]]; then
                                process_photo
                                stop="1"
                        else
                                msg="A mensagem enviada não está no formato de imagem, por favor envie uma imagem!"
                                send_message
                                next_id_update
                        fi
                elif [[ "${error}" != "null" ]]; then
                        echo "${error}" && exit 0
                else
                        continue;
                fi
        done
        stop="0"
}

function process_document_dae(){
        while true
        do
                updates="$(curl -s "https://api.telegram.org/bot${botTOKEN}/getupdates?offset=${offset}")"

                if [[ "${stop}" == "1" ]]; then
                        break
                fi

                result="$(echo $updates | jq -r ".result")"
                error="$(echo $updates | jq -r ".description")"

                if [[ "${result}" != "[]" ]]; then
                        update_id="$(echo $result | jq -r ".[0].update_id")"
                        text_received="$(echo $result | jq -r ".[0].message.text")"
                        document="$(echo $result | jq -r ".[0].message.document")"
                        if [[ "${document}" != "null" ]]; then
                                process_document
                                stop="1"
                        else
                                msg="A mensagem enviada não é um arquivo, por favor envie um arquivo!"
                                send_message
                                next_id_update
                        fi
                elif [[ "${error}" != "null" ]]; then
                        echo "${error}" && exit 0
                else
                        continue;
                fi
        done
        msg="Recebemos o seu documento!"
        stop="0"
}

function execute_dae_interact(){
        msg="Olá! Eu sou o BOT do DAE, o que gostaria de fazer?
        1- Enviar documento de identidade
        2- Enviar arquivos
        3- Sair da conversa
        "
        send_message
        next_id_update

        stop="0"
        while true
        do
                updates="$(curl -s "https://api.telegram.org/bot${botTOKEN}/getupdates?offset=${offset}")"

                if [[ ${stop} == "1" ]]; then
                        break
                fi

                result="$(echo $updates | jq -r ".result")"
                error="$(echo $updates | jq -r ".description")"

                if [[ "${result}" != "[]" ]]; then
                        update_id="$(echo $result | jq -r ".[0].update_id")"
                        text_received="$(echo $result | jq -r ".[0].message.text")"

                        if [[ "${text_received}" == "1" ]]; then
                                msg="Por favor envie seu documento de identidade em formato de imagem."
                                send_message
                                next_id_update

                                process_photo_dae
                                send_message
                                msg="Caso queira realizar outra operação basta digitar o número correspondente!"
                                interaction_type="photo"
        
                        elif [[ "${text_received}" == "2" ]]; then
                                msg="Por favor envie seu arquivo."
                                send_message
                                next_id_update

                                process_document_dae
                                send_message
                                msg="Caso queira realizar outra operação basta digitar o número correspondente!"
                                interaction_type="document"

                        elif [[ "${text_received}" == "3" ]]; then
                                msg="Obrigado por testar o BOT!"
                                stop="1"
                                interaction_type="exit_dae"

                        else
                                msg="Essa opção não existe, por favor reenvie a opção desejada."
                                interaction_type="inexistent_op_dae"
                        fi
                else
                        continue
                fi

                timestamp="$(echo $result | jq -r ".[0].message.date")"

                send_message
                next_id_update
                export_csv

                if [[ ${interaction_type} == "photo" ]]; then
                        image_type=$(($RANDOM % 3))
                        if [[ ${image_type} == 0 ]]; then
                                msg="A imagem enviada é um documento de identidade"
                        elif [[ ${image_type} == 1 ]];then
                                msg="A imagem enviada é um comprovante de residência"
                        else
                                msg="A imagem enviada é uma carteira de motorista"
                        fi
                        send_message
                        interaction_type=""
                fi
        done
}

function process_text(){
        text_received="$(echo $result | jq -r ".[0].message.text")"

        if [[ "${text_received}" == "/start" ]]; then
                msg="${default_msg}"
        elif [[ "${text_received}" == "DAE" ]]; then
                execute_dae_interact
                exit 0
        else
                python3 ${script_dir}/cerebro.py $user_id $text_received
                msg=`cat resp${user_id}.txt`
                if [[ "${msg}" == "Checklist" ]]; then
                        status_checklist_generate
                        msg="Este é o seu checklist:\nPAIZAO"
                fi
                #rm resp${user_id}.txt
        fi
}

function send_message(){
        msg_status=`curl -s -X POST -H 'Content-Type: application/json' \
                -d '{"chat_id": "'"${user_id}"'", "text": "'"${msg}"'"}' \
                https://api.telegram.org/bot${botTOKEN}/sendMessage`
}

function export_csv(){
        if [[ ! -e "${script_dir}/log.csv" ]]; then
                echo "Timestamp,BotName,ChatID,Tipo_Interacao,Mensagem_Do_Usuario,Situacao,JSON" \
                        >> ${script_dir}/log.csv
        fi

        echo $timestamp","$name_bot","$user_id","$interaction_type","$text_received",OK"","${user_json_dir}/${update_id}.json \
                >>  ${script_dir}/log.csv
}

set_basic_config
listen_usr