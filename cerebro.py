import sys
import os
import aiml

kernel = aiml.Kernel()

directory = os.path.dirname(os.path.realpath(__file__))

directoryBootstrap = directory + "/brain/std-startup.xml"
directoryBrain = directory + "/cerebro.brn"

def reset_bot():
    kernel.bootstrap(learnFiles = directoryBootstrap, commands = f"INICIAR TESTE")
    kernel.saveBrain(directoryBrain)

if os.path.isfile(directoryBrain):
    reset_bot()
else:
    reset_bot()
    
session_id = 1

session_data = kernel.getSessionData(session_id)

kernel.setBotPredicate("name", "rAVA")

def pre_processamento(msg):
    # Essa função vai executar qualquer pré-processamento relevante para a mensagem
    msg = msg.upper()
    
    return msg

def dispatcher(msg):
    # Essa função vai classificar a mensagem e retornar qual é o tipo de processamento alvo
    
    # Por enquanto só usamos o aiml
    if msg:
        tgt = 'aiml'
    
    return tgt

def run_test_from_file(file):
    f = open(file, mode='r', encoding="utf-8")
    test_logs = [['usr',l.strip()] for l in f]
    run_bot_with_logs(test_logs, test_mode=True)
    f.close()

def run_bot_with_logs(logs, test_mode=False):
    #print("RODANDO BOT COM LOGS: "+str(logs))
    for i, msg in enumerate(logs):
        
        entrada_usuario = pre_processamento(msg[1])
        
        tgt = dispatcher(entrada_usuario)

        if tgt == 'aiml':
            resp = kernel.respond(entrada_usuario, session_id)
        elif tgt == 'arit':
            # resp = aritmetica(entrada_usuario)
            pass
        elif tgt == 'logic':
            # resp = logica(entrada_usuario)
            pass
            
        if test_mode:
            print(f'> {entrada_usuario.lower()}')
            print(resp)
        if (i+1) == len(logs):
            return resp
     
def log(entrada, resposta, arq):
    arq.write(f'>>> {entrada.lower()}\n')
    arq.write(resposta.upper()+'\n')
    arq.write("\n")
   
def run_bot_terminal(fala, userID):
    #GERANDO ARQUIVO PARA ARMAZENAR AS FALAS DO USUÁRIO
    f_name = directory + "/interact" + userID + ".txt"
    f_userInteract = open(f_name, "a")
    fala += "\n"
    f_userInteract.write(fala)
    f_userInteract.close()
    ##

    #GERANDO ARQUVIO PARA O LOG DE CONVERSA
    n = ""
    k = 1
    if os.path.isfile("logs.txt"):
        while True:
            k += 1
            if not os.path.isfile(f'logs{str(k)}.txt'):
                n = str(k)
                break

    #logs = open(f'logs{n}.txt', "a", encoding='utf-8')
    ##

    f_userInteract = open(f_name, "r")
    userInteractList = f_userInteract.readlines()
    size = len(userInteractList)
    for i in range(size):
        entrada_usuario = pre_processamento(userInteractList[i])
        tgt = dispatcher(entrada_usuario)
        if tgt == 'aiml':
            resp = kernel.respond(entrada_usuario, session_id)
            if(i == size-1):
                f_name = directory + "/resp" + userID + ".txt"
                f_resp = open(f_name,"w")
                f_resp.write(resp)
                f_resp.close()
        elif tgt == 'arit':
            pass    
        elif tgt == 'logic':
            pass
    f_userInteract.close()
    

def saveAll():
    try:
        x = 0
        while True:
            if(x==0):
                entrada_usuario = pre_processamento("oi")
                x+=1
            else:
                entrada_usuario = pre_processamento(input("> "))
            
            if entrada_usuario in ["EXIT", "QUIT", "SAIR"]:
                print("FOI ÓTIMO CONVERSAR COM VOCÊ")
                #log(entrada_usuario, "FOI ÓTIMO CONVERSAR COM VOCÊ", logs)
                break
            
            tgt = dispatcher(entrada_usuario)
            
            if tgt == 'aiml':
                resp = kernel.respond(entrada_usuario, session_id)
            elif tgt == 'arit':
                # resp = aritmetica(entrada_usuario)
                pass
            elif tgt == 'logic':
                # resp = logica(entrada_usuario)
                pass
            
            print("")
            
            #log(entrada_usuario, resp, logs)
    
    except KeyboardInterrupt:
        print("")
        print("FOI ÓTIMO CONVERSAR COM VOCÊ")

def main():
    n = len(sys.argv)
    resp=""
    for i in range(2,n):
        resp += sys.argv[i] + " "
    if (n < 3):
        run_bot_terminal("",sys.argv[1])
    else:
        run_bot_terminal(resp,sys.argv[1])
    
if __name__ == "__main__":
    main()