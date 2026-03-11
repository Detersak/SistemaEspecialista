import requests
import clips
import sys

# ======================================================================
# 1. INTEGRAÇÃO COM A API DO BANCO CENTRAL (SGS)
# ======================================================================

def buscar_dado_bcb(codigo_serie):
    url = f"https://api.bcb.gov.br/dados/serie/bcdata.sgs.{codigo_serie}/dados/ultimos/1?formato=json"
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()
        dados = response.json()
        if dados:
            return float(dados[0]['valor'])
        return None
    except requests.exceptions.RequestException as e:
        print(f"Erro ao acessar a API do Banco Central: {e}")
        sys.exit(1)

def obter_indicadores_economicos():

    print("\nConsultando API do Banco Central...")
    selic =  buscar_dado_bcb(432) #Se quiser colocar um valor diferente da SELIC atual, basta comentar a chamada da função e colocar o valor manualmente, ex: selic = 13.75
    inflacao = buscar_dado_bcb(13522) #Mesma coisa...
    print(f"-> Dados capturados: Selic: {selic}% ao ano | IPCA (12m): {inflacao}%")
    return selic, inflacao

# ======================================================================
# 2. INTERFACE COM O USUÁRIO (PERFIL DO INVESTIDOR)
# ======================================================================

def obter_perfil_usuario():
    print("\n--- DEFINIÇÃO DO PERFIL DO INVESTIDOR ---")
    
    risco = ""
    while risco not in ['baixo', 'moderado', 'alto']:
        risco = input("Qual seu nível de risco aceitável? (baixo/moderado/alto): ").strip().lower()
        
    horizonte = ""
    while horizonte not in ['curto', 'medio', 'longo']:
        horizonte = input("Qual o horizonte de tempo? (curto/medio/longo): ").strip().lower()
        
    liquidez = ""
    while liquidez not in ['alta', 'baixa']:
        liquidez = input("Necessidade de liquidez/resgate rápido? (alta/baixa): ").strip().lower()
        
    return risco, horizonte, liquidez

# ======================================================================
# 3. INTEGRAÇÃO COM O SISTEMA ESPECIALISTA (CLIPS)
# ======================================================================

def executar_sistema_especialista(selic, inflacao, risco, horizonte, liquidez):
    """
    Inicia o ambiente CLIPS, carrega as regras, insere os fatos e extrai recomendações.
    """
    env = clips.Environment()
    
    # Carrega o arquivo com as regras criado anteriormente
    try:
        env.load("sistema_financeiro.clp")
    except Exception as e:
        print(f"Erro ao carregar o arquivo CLIPS: {e}")
        sys.exit(1)

    # 3.1 Injetar os Fatos de Indicadores Econômicos
    template_indicadores = env.find_template("indicadores-economicos")
    template_indicadores.assert_fact(selic=selic, inflacao=inflacao)

    # 3.2 Injetar os Fatos do Perfil do Investidor
    template_perfil = env.find_template("perfil-investidor")
    template_perfil.assert_fact(
        risco=clips.Symbol(risco), 
        horizonte=clips.Symbol(horizonte), 
        liquidez=clips.Symbol(liquidez)
    )
    print("\nProcessando motor de inferência lógico...")
    
    # 3.3 Executar as regras (Forward Chaining)
    env.run()

    # 3.4 Extrair os resultados gerados
    recomendacoes = []
    for fact in env.facts():
        if fact.template.name == "recomendacao":
            recomendacoes.append({
                "classe_ativo": fact["classe-ativo"],
                "produto": fact["produto"],
                "grau_confianca": fact["grau-confianca"],
                "justificativa": fact["justificativa"]
            })
            
    return recomendacoes

# ======================================================================
# 4. EXECUÇÃO PRINCIPAL
# ======================================================================

if __name__ == "__main__":
    print("=====================================================")
    print("SISTEMA ESPECIALISTA DE ALOCAÇÃO DE ATIVOS FINANCEIROS")
    print("=====================================================")
    
    # 1. Pega dados macroeconômicos
    selic, inflacao = obter_indicadores_economicos()
    
    # 2. Pega dados do usuário
    risco, horizonte, liquidez = obter_perfil_usuario()
    
    # 3. Roda o motor de inferência
    recomendacoes = executar_sistema_especialista(selic, inflacao, risco, horizonte, liquidez)
    
    print("\n=====================================================")
    print("RECOMENDAÇÕES DE INVESTIMENTO GERADAS")
    print("=====================================================\n")
    
    if not recomendacoes:
        print("Nenhuma recomendação específica encontrada para o seu perfil neste cenário macroeconômico.")
    else:
        recomendacoes_ordenadas = sorted(recomendacoes, key=lambda x: x['grau_confianca'], reverse=True)
        
        for i, rec in enumerate(recomendacoes_ordenadas, 1):
            print(f"Recomendação #{i} (Confiança: {rec['grau_confianca']}%)")
            print(f"  * Classe de Ativo: {rec['classe_ativo']}")
            print(f"  * Produto: {rec['produto']}")
            print(f"  * Por que investir: {rec['justificativa']}")
            print("-" * 50)