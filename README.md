# Sistema Especialista em Alocação de Ativos Financeiros

Este repositório contém a implementação de um Sistema Especialista baseado em regras focado em recomendações de investimentos. O projeto utiliza a linguagem CLIPS para o motor de inferência lógico e Python para o controle de fluxo, interface e integração com APIs externas.

## Sobre o Projeto

O sistema atua como uma ferramenta de apoio à tomada de decisão financeira. Em vez de utilizar estruturas condicionais rígidas (if/else), a aplicação separa a Base de Conhecimento (regras financeiras) do mecanismo de controle. 

O sistema consome dados em tempo real da API do Sistema Gerenciador de Séries Temporais (SGS) do Banco Central do Brasil, capturando a Taxa Selic Meta e a inflação (IPCA) acumulada dos últimos 12 meses. Utilizando o algoritmo de Encadeamento para Frente (Forward Chaining), o motor de inferência deduz o cenário macroeconômico atual e cruza esses fatos com o perfil de risco, horizonte de tempo e liquidez do usuário para emitir recomendações baseadas em fatores de certeza heurísticos.

## Arquitetura e Tecnologias

* Lógica Baseada em Regras: CLIPS (C Language Integrated Production System)
* Controlador e Integração: Python 3
* Bibliotecas Python:
  * clipspy: Integração nativa do ambiente CLIPS no Python.
  * requests: Consumo de dados da API do Banco Central.

## Estrutura de Arquivos

* sistema_financeiro.clp: Arquivo contendo a Base de Conhecimento. Define os deftemplate (estruturas de dados) e as defrule (regras de inferência macroeconômica e de recomendação de ativos).
* main.py: Script principal que gerencia o input do usuário, busca os dados da API do BCB, injeta os fatos na Memória de Trabalho do CLIPS e extrai os resultados processados.

## Pré-requisitos e Instalação

Certifique-se de ter o Python 3.x instalado em sua máquina. Recomenda-se o uso de um ambiente virtual (venv).

1. Clone este repositório:
git clone https://github.com/Detersak/SistemaEspecialista.git
cd SistemaEspecialista

2. Instale as dependências necessárias:
pip install clipspy requests

## Como Executar

Para iniciar o sistema, basta rodar o script principal via terminal. O sistema fará a requisição automática dos indicadores econômicos e solicitará os dados do seu perfil de investidor.

python main.py

### Exemplo de Fluxo de Execução
1. O sistema acessa a API do Banco Central e captura a Selic e o IPCA atuais.
2. O usuário preenche as diretrizes:
   * Nível de risco (baixo, moderado, alto)
   * Horizonte de tempo (curto, medio, longo)
   * Necessidade de liquidez (alta, baixa)
3. O motor CLIPS processa os dados e retorna as classes de ativos recomendadas (Renda Fixa, Variável, Criptomoedas, etc.), ordenadas pelo grau de confiança do especialista.

## Autor

Arthur Kollmann
