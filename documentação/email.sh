SERVIDOR="nathan@www.qsabe.com.br"
SENHA="1234@LCAD"

DE="nathangarfreitas@gmail.com"
PARA="nathangarfreitas@gmail.com"
CC="nathan.freitas@edu.ufes.br"
CCO="nathan.freitas@edu.ufes.br"
ASSUNTO="Assunto do e-mail"
CORPO="Corpo do e-mail"
ANEXO="next_id.txt"

echo "$CORPO" | mailx -s smtp="$SERVIDOR" \
-s smtp-auth-user="$DE" \
-s smtp-auth-password="$SENHA" \
-s smtp-use-starttls \
-r "$DE" -s "$ASSUNTO" -c "$CC" -b "$CCO" -a "$ANEXO" "$PARA"
