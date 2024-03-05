#!/bin/bash
botTOKEN=""
offset="0"
pipeline="$1"

default_msg="Ola estou na versao 1.0, sou o "
interaction_type=""
image_type=""
name=""

status_id=""
status_resid=""
user_email=""

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

        if [ ! -f "${user_dir}/doc_confirm.txt" ]; then
                touch "${user_dir}/doc_confirm.txt"
        fi

        if [ ! -f "${user_dir}/resid_confirm.txt" ]; then
                touch "${user_dir}/resid_confirm.txt"
        fi

        if [ ! -f "${user_dir}/email.txt" ]; then
                touch "${user_dir}/email.txt"
        fi

        if [ ! -f "${user_dir}/username.txt" ]; then
                touch "${user_dir}/username.txt"
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
        doc_conf=`cat ${script_dir}/${1}/doc_confirm.txt`
        resid_conf=`cat ${script_dir}/${1}/resid_confirm.txt`

        if [[ ${doc_conf} != "" ]]; then
                status_id="1"
        fi

        if [[ ${resid_conf} != "" ]]; then
                status_resid="1"
        fi
}

function next_id_update(){
        offset="$((update_id + 1))"
        echo $offset > ${script_dir}/next_id.txt
}

function listen_usr(){
        while true 
        do
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
                        username=`cat "${user_dir}/username.txt"`
                        if [[ ${username} != "" ]]; then
                                if [[ $msg == *${username}* ]]; then
                                        msg="Documento de identidade recebido"
                                else
                                        python3 ${script_dir}/cerebro.py $user_id "NOME NAO COMPATIVEL"
                                        msg=`cat resp${user_id}.txt`
                                fi
                        else
                                python3 ${script_dir}/cerebro.py $user_id "NOME NAO INFORMADO"
                                msg=`cat resp${user_id}.txt`
                        fi
                elif [[ ${image_type} == 1 ]]; then
                        msg="A imagem enviada é um comprovante de residência"
                else
                        msg="Tipo de documento não reconhecido"
                fi
                interaction_type=""
        fi
        send_message

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


        if [[ $msg == *"NOME"* ]] && [[ $msg == *"CPF"* ]] && [[ $msg == *"VALIDA EM TODO O TERRITORIO NACIONAL"* ]]; then
                image_type="0"
                echo "1" > ${user_dir}/doc_confirm.txt
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

function process_text(){
        text_received="$(echo $result | jq -r ".[0].message.text")"

        if [[ "${text_received}" == "/start" ]]; then
                msg="${default_msg}"
        else
                #if [[ ${text_received} == *".com"* ]] && [[ ${text_received} == *"@"* ]]; then
                #        echo "EMAIL RECEBIDO"
                #fi
                python3 ${script_dir}/cerebro.py $user_id $text_received
                msg=`cat resp${user_id}.txt`
                if [[ "${msg}" == "CHECKLIST" ]]; then
                        #check_email
                        #if [[ ${email} != "" ]]; then
                                #status_checklist_generate
                                #generate_checklist
                        #else
                                #python3 ${script_dir}/cerebro.py $user_id "EMAIL"
                                #msg=`cat resp${user_id}.txt`
                        #fi
                        status_checklist_generate ${user_id}
                        generate_checklist ${user_id}

                        echo -e $msg > ${script_dir}/checklist.txt
                        cupsfilter ${script_dir}/checklist.txt > ${script_dir}/checklist.pdf

                        send_document ${script_dir}/checklist.pdf
                        msg="Checklist enviada."
                        rm ${script_dir}/checklist.pdf
                        rm ${script_dir}/checklist.txt

                elif [[ "${msg}" == "CHECKLIST GERAL" ]]; then
                        generate_geral_checklist
                        msg="Checklist Geral enviada."

                elif [[ "${msg}" == "NOME RECEBIDO" ]]; then
                        python3 ${script_dir}/cerebro.py $user_id "ENVIAR NOME USUARIO ATUAL"
                        name=`cat resp${user_id}.txt`

                        save_name

                        python3 ${script_dir}/cerebro.py $user_id "RESPOSTA NOME"
                        msg=`cat resp${user_id}.txt`

                elif [[ "${msg}" == "NOME RECEBIDO ID" ]]; then 
                        python3 ${script_dir}/cerebro.py $user_id "ENVIAR NOME USUARIO ATUAL"
                        name=`cat resp${user_id}.txt`

                        save_name

                        python3 ${script_dir}/cerebro.py $user_id "RESPOSTA NOME ID"
                        msg=`cat resp${user_id}.txt`

                #elif [[ "${msg}" == "EMAIL RECEBIDO" ]]; then 
                #        python3 ${script_dir}/cerebro.py $user_id "ENVIAR EMAIL USUARIO ATUAL"
                #        email=`cat resp${user_id}.txt`

                #        save_email

                #        python3 ${script_dir}/cerebro.py $user_id "RESPOSTA EMAIL"
                #        msg=`cat resp${user_id}.txt`
                
                elif [[ "${msg}" == "CUMPRIMENTO" ]]; then
                        name=`cat "${user_dir}/username.txt"`
                        if [ ${name} != "" ]; then
                                python3 ${script_dir}/cerebro.py $user_id "CUMPRIMENTO POSTERIOR"
                                msg=`cat resp${user_id}.txt`
                        else
                                python3 ${script_dir}/cerebro.py $user_id "CUMPRIMENTO INICIAL"
                                msg=`cat resp${user_id}.txt`
                        fi
                fi
        fi
}

function send_message(){
        msg_status=`curl -s -X POST "https://api.telegram.org/bot${botTOKEN}/sendMessage" \
                -d "chat_id=${user_id}" \
                -d "text=$msg"`
}

function send_document(){
        curl -s -X POST "https://api.telegram.org/bot${botTOKEN}/sendDocument" \
                -F "chat_id=${user_id}" \
                -F "document=@${1}"
        }

function export_csv(){
        if [[ ! -e "${script_dir}/log.csv" ]]; then
                echo "Timestamp,BotName,ChatID,Tipo_Interacao,Mensagem_Do_Usuario,Situacao,JSON" \
                        >> ${script_dir}/log.csv
        fi

        echo $timestamp","$name_bot","$user_id","$interaction_type","$text_received",OK"","${user_json_dir}/${update_id}.json \
                >>  ${script_dir}/log.csv
}

function generate_checklist(){
        msg="Checklist de ${1}\nDocumento de identidade: "
        if [[ ${status_id} != "" ]]; then
                msg="${msg} V\n"
        else
                msg="${msg} X\n"
        fi

        msg="${msg}Comprovante de residência: "
        if [[ ${status_resid} != "" ]]; then
                msg="${msg} V"
        else
                msg="${msg} X"
        fi
        msg="${msg}\n\n"
}

function generate_geral_checklist(){
        if [[ ! -f "${script_dir}/checklist.txt" ]]; then
                touch "${script_dir}/checklist.txt"
        fi
        relatorio="Checklist rAVA\n\n"

        ls -d */ > diretorios.txt
        arquivo="diretorios.txt"

        while read -r linha; do
        if [[ -f "${script_dir}/${linha}/username.txt" ]]; then
                user_id_atual="$(echo $linha | cut -d "/" -f1)"
                status_checklist_generate ${user_id_atual}
                generate_checklist ${user_id_atual}
                relatorio="$relatorio $msg"
        fi
        echo -e $relatorio > "${script_dir}/checklist.txt"
        cupsfilter ${script_dir}/checklist.txt > ${script_dir}/checklist.pdf
        done < "$arquivo"

        send_document "${script_dir}/checklist.pdf"
        rm "${script_dir}/checklist.txt"
        rm "${script_dir}/diretorios.txt"
        rm "${script_dir}/checklist.pdf"
}

function check_email(){
    email=`cat ${user_dir}/email.txt`
}

function save_email(){
        echo $email > ${user_dir}/email.txt
}

function save_name(){
        echo $name > ${user_dir}/username.txt
}

set_basic_config
listen_usr