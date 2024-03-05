import sys
import re

# Abstração do banco de dados de livros
class Livro():
    def __init__(self, nome, autor, preco):
        self.nome = nome
        self.autor = autor
        self.preco = preco
        
    def __str__(self):
        return f'\'{self.nome}\', escrito por {self.autor} [R${self.preco}]'
    
livros = []
livros.append(Livro("Dom Quixote", "Miguel de Cervantes", 10))
livros.append(Livro("Dracula", "Bram Stoker", 20))
livros.append(Livro("Admiravel Mundo Novo", "Aldous Huxley", 30))
livros.append(Livro("1984", "George Orwell", 40))
livros.append(Livro("Metamorfose", "Franz Kafka", 50))
livros.append(Livro("Memorias Postumas de Bras Cubas", "Machado de Assis", 60))
livros.append(Livro("Dom Casmurro", "Machado de Assis", 70))
livros.append(Livro("Quincas Borba", "Machado de Assis", 80))
livros.append(Livro("Kizumonogatari", "Nisio Isin", 90))
livros.append(Livro("Lolita", "Vladmir Nobokov", 100))
livros.append(Livro("A Arte da Guerra", "Sun Tzu", 110))

def checa_se_tem(nome, autor):
    
    #print(f'testando NOME:{str(nome)} e AUTOR:{str(autor)}')
    
    for livro in livros:
        if nome == livro.nome.upper():
            if autor and autor == livro.autor.upper():
                return "SIM"
            elif not autor:
                return "SIM"
            
    return "NAO"

def lista_livros():
    
    #print("Lista de Livros")
    
    saida = ""
    for i, livro in enumerate(livros):
        saida += str(livro)
        if (i+1) < len(livros):
            saida += "; "

    #print(saida)            
    return saida

def lista_livros_por_autor(autor):
    
    #print(f'buscando livros do autor: {str(autor)}')

    saida = ""
    for i, livro in enumerate(livros):
        if autor.upper() == livro.autor.upper():
            saida += str(livro)
            if (i+1) < len(livros):
                saida += "; "
                
    return saida

def preco_livro(nome):
    #print(f'pegando o preço de: {str(nome)}')
    
    entrada = []
    if re.search(" DE ", nome):
        entrada = nome.split(" DE ")        
        nome = entrada[0]
    
    if checa_se_tem(nome, None) == 'SIM':    
        for livro in livros:
            if nome.upper() == livro.nome.upper():
                return f'R$ {str(livro.preco)}'
    else:
        return f'NAO TEMOS ESSE LIVRO'
            


def main():
    #print(f'rodando com argv={str(sys.argv)}')
    
    if len(sys.argv) >= 2:
        command = sys.argv[1]
    else:
        print("Sem Comando")
        return
    
    if command == 'lista':
        saida = lista_livros()
    
    elif sys.argv[2:]:
 
        string_entrada = ""
        list = sys.argv[2:]
        for i, p in enumerate(list):
            string_entrada += p
            if i+1 < len(list):
                string_entrada += " "        
        
        if command == 'autor':
            
            saida = lista_livros_por_autor(string_entrada)

        elif command == 'checa':
            
            #print(f'checando com entrada={str(string_entrada)}')
            entrada = []
            if re.search(" DE ", string_entrada):
                entrada = string_entrada.split(" DE ")        
                nome = entrada[0]
                autor = entrada[1]    
            else:    
                nome = string_entrada
                autor = None
                
            #print(f'checando com nome={str(nome)} e autor={str(autor)}')
            
            saida = checa_se_tem(nome, autor)
            if saida == 'SIM':
                saida = 'TEMOS SIM'
            else:
                saida = 'NÃO TEMOS'
            
            
        elif command == 'preco':
            
            if re.search(" DE ", string_entrada):
                entrada = string_entrada.split(" DE ")
            
                saida = preco_livro(entrada[0])
            
            else:    
                saida = preco_livro(string_entrada)
            
            
        else:
            print("Comando não existente")
            return
    
    
    else:
        print("Sem argumento para o comando")
        return
            
    print(saida)


if __name__ == "__main__":
    main()