;;Arthur Kollmann Deters
;; ----------------------------------------------------------------------
;; 1. DEFINIÇÃO DE TEMPLATES (ESTRUTURAS DE DADOS)
;; ----------------------------------------------------------------------

;; Dados recebidos da API do Banco Central via Python
(deftemplate indicadores-economicos
    (slot selic (type FLOAT))
    (slot inflacao (type FLOAT)))

;; Dados recebidos do input do usuário via Python
(deftemplate perfil-investidor
    (slot risco (allowed-values baixo moderado alto) (default baixo))
    (slot horizonte (allowed-values curto medio longo) (default curto))
    (slot liquidez (allowed-values alta baixa) (default alta)))

;; Fatos intermediários deduzidos pelo motor de inferência
(deftemplate cenario-macro
    (slot juros (allowed-values altos neutros baixos))
    (slot pressao-inflacionaria (allowed-values alta controlada)))

;; Resultado final que será lido pelo Python
(deftemplate recomendacao
    (slot classe-ativo (type STRING))
    (slot produto (type STRING))
    (slot grau-confianca (type INTEGER)) ; 1 a 100
    (slot justificativa (type STRING)))

;; ----------------------------------------------------------------------
;; 2. REGRAS DE INFERÊNCIA MACROECONÔMICA (FATOS INTERMEDIÁRIOS)
;; ----------------------------------------------------------------------

;; Regra: Juros Altos (Selic acima de 9.5%)
(defrule analisa-juros-altos
    (indicadores-economicos (selic ?s&:(>= ?s 9.5)))
    =>
    (assert (cenario-macro (juros altos)))
    (printout t "-> ANALISE: Cenário de juros altos detectado (" ?s "%)." crlf))

;; Regra: Juros Neutros (Selic entre 6.5% e 9.5%)
(defrule analisa-juros-neutros
    (indicadores-economicos (selic ?s&:(< ?s 9.5)&:(>= ?s 6.5)))
    =>
    (assert (cenario-macro (juros neutros)))
    (printout t "-> ANALISE: Cenário de juros neutros detectado (" ?s "%)." crlf))

;; Regra: Juros Baixos (Selic abaixo de 6.5%)
(defrule analisa-juros-baixos
    (indicadores-economicos (selic ?s&:(< ?s 6.5)))
    =>
    (assert (cenario-macro (juros baixos)))
    (printout t "-> ANALISE: Cenário de juros baixos detectado (" ?s "%)." crlf))

;; Regra: Pressão Inflacionária Alta (IPCA acima de 4.5% - Teto da meta)
(defrule analisa-inflacao-alta
    (indicadores-economicos (inflacao ?i&:(> ?i 4.5)))
    =>
    (assert (cenario-macro (pressao-inflacionaria alta)))
    (printout t "-> ANALISE: Pressao inflacionaria alta detectada (" ?i "%)." crlf))

;; Regra: Inflação Controlada (IPCA <= 4.5%)
(defrule analisa-inflacao-controlada
    (indicadores-economicos (inflacao ?i&:(<= ?i 4.5)))
    =>
    (assert (cenario-macro (pressao-inflacionaria controlada)))
    (printout t "-> ANALISE: Inflacao controlada (" ?i "%)." crlf))

;; ----------------------------------------------------------------------
;; 3. REGRAS DE RECOMENDAÇÃO DE INVESTIMENTOS
;; ----------------------------------------------------------------------

;; Recomendação: Reserva de Emergência (Sempre necessário para liquidez alta)
(defrule rec-reserva-emergencia
    (perfil-investidor (liquidez alta))
    (cenario-macro (juros ?j))
    =>
    (assert (recomendacao 
        (classe-ativo "Renda Fixa Pós-Fixada")
        (produto "Tesouro Selic ou CDB 100% CDI Liquidez Diária")
        (grau-confianca 95)
        (justificativa "Sua necessidade de alta liquidez exige ativos sem volatilidade e com resgate imediato."))))

;; Recomendação: Proteção contra Inflação (IPCA alto e horizonte médio/longo)
(defrule rec-protecao-inflacao
    (cenario-macro (pressao-inflacionaria alta))
    (perfil-investidor (horizonte ?h&medio|longo))
    =>
    (assert (recomendacao 
        (classe-ativo "Renda Fixa Indexada à Inflação")
        (produto "Tesouro IPCA+ ou Debêntures Incentivadas")
        (grau-confianca 90)
        (justificativa "Com a inflação acima da meta, é fundamental proteger o poder de compra do seu capital no médio/longo prazo."))))

;; Recomendação: Aproveitar Juros Altos com isenção de IR (Baixa liquidez)
(defrule rec-isencao-ir-juros-altos
    (cenario-macro (juros altos))
    (perfil-investidor (liquidez baixa) (risco ?r&baixo|moderado))
    =>
    (assert (recomendacao 
        (classe-ativo "Renda Fixa Isenta")
        (produto "LCI ou LCA pré-fixada/pós-fixada")
        (grau-confianca 85)
        (justificativa "Com juros altos e sem necessidade de liquidez imediata, LCI/LCA oferecem excelente rentabilidade isenta de Imposto de Renda."))))

;; Recomendação: Renda Variável (Ações) em cenário de juros baixos ou risco alto
(defrule rec-acoes-crescimento
    (cenario-macro (juros baixos))
    (perfil-investidor (risco alto) (horizonte longo))
    =>
    (assert (recomendacao 
        (classe-ativo "Renda Variável")
        (produto "Carteira Diversificada de Ações (Ibovespa / Small Caps)")
        (grau-confianca 80)
        (justificativa "Com a Selic baixa, o prêmio de risco da renda fixa cai. O cenário é ideal para buscar crescimento patrimonial em ações no longo prazo."))))

;; Recomendação: Fundos Imobiliários (FIIs) para geração de renda
(defrule rec-fiis-renda
    (cenario-macro (juros neutros|baixos))
    (perfil-investidor (risco ?r&moderado|alto) (horizonte longo))
    =>
    (assert (recomendacao 
        (classe-ativo "Renda Variável (Imobiliária)")
        (produto "Fundos Imobiliários (FIIs) de Tijolo e Papel")
        (grau-confianca 80)
        (justificativa "FIIs são excelentes para geração de renda passiva recorrente, especialmente com juros cedendo, o que valoriza as cotas."))))

;; Recomendação: Diversificação Internacional (Sempre para perfis moderados/altos)
(defrule rec-diversificacao-global
    (perfil-investidor (risco ?r&moderado|alto) (horizonte ?h&medio|longo))
    =>
    (assert (recomendacao 
        (classe-ativo "Exterior")
        (produto "ETFs Internacionais (ex: IVVB11, WRLD11)")
        (grau-confianca 75)
        (justificativa "A diversificação em moeda forte (Dólar) e em mercados globais reduz o risco-país (Brasil) da sua carteira."))))

;; Recomendação: Renda Fixa Pré-fixada (Travando taxas em juros altos)
(defrule rec-prefixado-travar-taxa
    (cenario-macro (juros altos) (pressao-inflacionaria controlada))
    (perfil-investidor (horizonte medio) (liquidez baixa))
    =>
    (assert (recomendacao 
        (classe-ativo "Renda Fixa Pré-fixada")
        (produto "Tesouro Prefixado ou CDB Prefixado")
        (grau-confianca 85)
        (justificativa "Com juros altos e inflação controlada, travar uma taxa alta agora garantirá um rendimento real expressivo mesmo que a Selic caia no futuro."))))
;; Recomendação: Criptoativos (Risco Alto e Longo Prazo)
(defrule rec-criptomoedas
    (perfil-investidor (risco alto) (horizonte longo))
    (cenario-macro (juros ?j)) ; Exigência para garantir controle de fluxo
    =>
    (assert (recomendacao 
        (classe-ativo "Ativos Alternativos / Criptomoedas")
        (produto "Bitcoin (BTC) ou Ethereum (ETH)")
        (grau-confianca 70)
        (justificativa "Seu perfil de alto risco e longo prazo permite uma pequena alocacao em criptoativos para buscar retornos assimetricos, suportando a alta volatilidade."))))

;; Recomendação: Ações de Dividendos / Value Investing
(defrule rec-acoes-dividendos
    (cenario-macro (juros altos|neutros))
    (perfil-investidor (risco ?r&moderado|alto) (horizonte longo))
    =>
    (assert (recomendacao 
        (classe-ativo "Renda Variável (Dividendos)")
        (produto "Carteira de Ações Pagadoras de Dividendos (Bancos, Saneamento, Energia)")
        (grau-confianca 75)
        (justificativa "Mesmo sem a Selic estar na minima, empresas consolidadas e boas pagadoras de dividendos oferecem geracao de renda passiva e resiliencia."))))

;; Recomendação: Fundos Multimercado (Delegação de Gestão)
(defrule rec-fundos-multimercado
    (perfil-investidor (risco moderado) (horizonte ?h&medio|longo) (liquidez baixa))
    (cenario-macro (juros ?j))
    =>
    (assert (recomendacao 
        (classe-ativo "Fundos de Investimento")
        (produto "Fundos Multimercado Macro")
        (grau-confianca 80)
        (justificativa "Ideal para delegar a gestao a profissionais que operam juros, moedas e bolsa simultaneamente, buscando superar o CDI com risco controlado."))))

;; Recomendação: Ouro ou Proteção Patrimonial (Hedge)
(defrule rec-ouro-hedge
    (cenario-macro (pressao-inflacionaria alta))
    (perfil-investidor (risco ?r&moderado|alto))
    =>
    (assert (recomendacao 
        (classe-ativo "Proteção / Hedge")
        (produto "Ouro (OZ1D ou fundos atrelados ao ouro)")
        (grau-confianca 85)
        (justificativa "Em cenarios de pressao inflacionaria resistente, o ouro atua como uma reserva de valor historica, protegendo o patrimonio contra a desvalorizacao da moeda."))))