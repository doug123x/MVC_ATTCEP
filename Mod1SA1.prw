#INCLUDE 'TOTVS.ch'
#INCLUDE 'FwMvcDef.ch'

/*
	@author DOUGLAS DE SOUSA DOURADO
	ESSE FONTE TEM COMO OBJETIVO A ATUALIZAÇAO DO ENDEREÇO DO CLIENTE COM BASE NO CEP ...
	Tentado utilizar diversos metodos, como MVC, REST, ExecAuto, etc...
	*Necessario o fonte APICORREIOS.prw tb compilado no RPO ...
	To Do: 
		-> Relatorio (TReport) com perguntas (SX1): de cliente ate cliente e listar clientes/enderecos no relatorio ...
		-> Importar CSV para atualizacao em massa ...
*/

Static cTitulo := "Atualizar Endereço Cliente (MVC Mod.1)"

// Deve ser o mesmo nome do fonte, Mod1Sa1.prw ...
User Function Mod1SA1()

    Local aArea    := FWGetArea()
	Local oBrowse
	
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("SA1")
	oBrowse:SetMenuDef("Mod1SA1")
	oBrowse:SetDescription(cTitulo)
	
	//Legendas
	oBrowse:AddLegend( "SA1->A1_CEP == ''" 						  , "RED"  	  ,	"Sem CEP cadastrado" )
	oBrowse:AddLegend( "SA1->A1_CEP != '' .AND. SA1->A1_END == ''", "YELLOW"  ,	"Endereço não informado" )
	oBrowse:AddLegend( "SA1->A1_CEP != '' .AND. SA1->A1_END != '' ", "GREEN"  ,	"OK" )

    // Limita quais campos vao aparecer no browser
    oBrowse:SetOnlyFields({"A1_COD", "A1_LOJA", "A1_NOME", "A1_CEP", "A1_EST", "A1_MUN", "A1_END", "A1_BAIRRO","A1_COMPLEM"})

    // Desabilita o "detalhes" na parte inferior do browser
    //oBrowse:DisableDetails()
	
	//Ativa a Browse
	oBrowse:Activate()
	
	FWRestArea(aArea)

return

/* Camada de Controle */
Static Function MenuDef()

    Local aRot := {}
	
	// Adicionando opções
	ADD OPTION aRot TITLE 'Visualizar' ACTION 'VIEWDEF.Mod1SA1' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
	ADD OPTION aRot TITLE 'Atualizar Endereço por CEP (digitação)'   ACTION 'u_CEPBox'     	OPERATION 2                      ACCESS 0 //OPERATION X
	ADD OPTION aRot TITLE 'Legenda'    	 ACTION 'u_zSA1Leg'     	OPERATION 6                      ACCESS 0 //OPERATION X
	//ADD OPTION aRot TITLE 'Incluir'    ACTION 'VIEWDEF.Mod1SA1' OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
	//ADD OPTION aRot TITLE 'Alterar'    ACTION 'VIEWDEF.Mod1SA1' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
	//ADD OPTION aRot TITLE 'Excluir'    ACTION 'VIEWDEF.Mod1SA1' OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5

Return aRot

// Monta o Dialog para preencher o CEP ...
User Function CEPBox()
	
	Local aArea    := FWGetArea()
	
	//Dimensões da janela
	Local nJanAltu := 160
	Local nJanLarg := 600
	//Objetos da janela
	Private oSayCEP, oGetCEP, cGetCEP := Space(08)
	Private oSayEnd,  oGetEnd,  cGetEnd  := Space(200)
	Private oDlgCEP
	Private aDados
	
	//Criando a janela
	DEFINE MSDIALOG oDlgCEP TITLE "Atualizar Endereço (Manual)" FROM 000, 000  TO nJanAltu, nJanLarg COLORS 0, 16777215 PIXEL //STYLE DS_MODALFRAME (tira o botao de cancelar o dialog)
		
		//Get CEP
		@ 041, 006 SAY        oSayCEP PROMPT "CEP:"                     								SIZE 050, 007 PIXEL OF oDlgCEP 
		@ 038, 040 MSGET      oGetCEP VAR    cGetCEP 	PICTURE "@R 99999-999" VALID ValidCep(cGetCEP)  SIZE 030, 010 PIXEL OF oDlgCEP 
								
		//Get Endereco
		@ 061, 006 SAY        oSayEnd  PROMPT "Endereco:"                      SIZE 050, 007 PIXEL OF oDlgCEP 
		@ 058, 040 MSGET      oGetEnd  VAR    cGetEnd              WHEN .F.    SIZE 150, 010 PIXEL OF oDlgCEP 

		@ 058, 190 BUTTON "Buscar Endereco (WS Correios)" Size 100,12 WHEN .T. PIXEL OF oDlgCEP action zGetEnd(cGetCEP)
		//oDlgCEP:lEscClose := .F. // Nao deixa o usuario fechar o dialog apertando ESC
	
	ACTIVATE MSDIALOG oDlgCEP on Init EnchoiceBar(oDlgCEP, {|| U_zSaveEnd(aDados) }, {|| oDlgCEP:End()}, Nil, Nil) CENTERED

	FWRestArea(aArea)

Return

// Valida e faz a chamada para o exec auto ...
User Function zSaveEnd(aDados)

	if( ValType( aDados ) == "A" .and. LEN( aDados )  > 0 )
		FWMsgRun(, {|oSayAuto| zAttSA1( aDados , oSayAuto) }, "Processando", "Salvando dados via exec auto ...")
	endif

Return

// Valida e depois faz a chamada para o WS ...
Static Function zGetEnd( cGetCEP )
	IF LEN(cGetCEP) == 8
		FWMsgRun(, {|oSay| fWSCorreio( cGetCEP , oSay) }, "Processando", "Iniciando chamada para WS ViaCEP ...")
	else
		MSGALERT( "CEP deve conter 8 digitos!", "Valida CEP" )
	Endif
Return

// Chama o WS e armazena os dados do endereco na variavel aDados ...
Static Function fWSCorreio( cGetCEP , oSay )

	IF LEN(cGetCEP) != 8
		MSGALERT( "CEP deve conter 8 digitos!", "Valida CEP" )
		Return
	ENDIF
	
	aDados := U_APICORREIOS(cGetCEP) // Retorna um objeto com todos os dados do endereço, tipo LOGRADOURO, COMPLEMENTO, MUNICIPIO ...

	if( ValType( aDados ) == "A" .and. LEN( aDados )  > 0 )
		cGetEnd := aDados[6] // endereco completo 
	else
		MSGALERT( "Nao foi possivel buscar o CEP no WS dos Correios", "Retorno não esperado do WS" )
	endif
	
Return

// Validacao do CEP para o Dialog
Static Function ValidCEP( cGetCep )

	If ( LEN( Alltrim(cGetCep) ) <> 8  )
		MSGALERT( "CEP deve conter 8 digitos !!! ( " + Alltrim( STR( LEN( Alltrim(cGetCep) ) ) ) + " digitos encontrados )", "Validação de CEP" )
		Return .F.
	Endif

Return .T.

/* Modelo de Dados */
Static Function ModelDef()
    
    //Criação do objeto do modelo de dados
	Local oModel := Nil	
	Local oStSA1 := FWFormStruct(1, "SA1")    
	
	//Instanciando o modelo, não é recomendado colocar nome da user function (por causa do u_), respeitando 10 caracteres
	oModel := MPFormModel():New("Mod1SA1z",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/) 
	
	//Atribuindo formulários para o modelo
	oModel:AddFields("FORMSA1",/*cOwner*/,oStSA1)
	
	//Setando a chave primária da rotina
	oModel:SetPrimaryKey({'A1_FILIAL','A1_CODIGO'})
	
	//Adicionando descrição ao modelo
	oModel:SetDescription("Modelo de Dados do Cadastro "+cTitulo)
	
	//Setando a descrição do formulário
	oModel:GetModel("FORMSA1"):SetDescription("Formulário do Cadastro "+cTitulo)

Return oModel

/* VisÃ£o - tudo que exibido na tela */
Static Function ViewDef()

	Local oModel := FWLoadModel("Mod1SA1")
	Local oStSA1 := FWFormStruct(2, "SA1") 
	Local oView := Nil

	oView := FWFormView():New()
	oView:SetModel(oModel)
	
	oView:AddField("VIEW_SA1", oStSA1, "FORMSA1")
	
	oView:CreateHorizontalBox("TELA",100)
	
	oView:EnableTitleView('VIEW_SA1', 'Dados do Cliente' )  
	
	oView:SetCloseOnOk({||.T.})
	
	oView:SetOwnerView("VIEW_SA1","TELA")

Return oView

/* Legenda do Browser */
User Function zSA1Leg()
	Local aLegenda := {}
	
	//Monta as cores
	AADD(aLegenda,{"BR_VERDE",		"CEP E Endereço OK"  })
	AADD(aLegenda,{"BR_AMARELO",	"Endereço não informado"  })
	AADD(aLegenda,{"BR_VERMELHO",	"Sem CEP cadastrado"})

	BrwLegenda("Status CEP/Endereço", "CEP", aLegenda)
Return

// Chama o exec auto CRMA980 para atualizar os campos endereços ...
Static Function zAttSA1( oDadosEnd , oSayAuto )

/*
Exemplo do oDadosEnd:
	oDadosEnd[1] // LOGRADOURO
	oDadosEnd[2] // COMPLEMENTO
	oDadosEnd[3] // BAIRRO
	oDadosEnd[4] // LOCALIDADE
	oDadosEnd[5] // UF
	oDadosEnd[6] // Endereço completo (todas opcoes anteriores concatenadas)
*/
 
Local aSA1Auto  := {}
Local aAI0Auto  := {}
Local nOpcAuto  := MODEL_OPERATION_UPDATE
Local lRet      := .T.
 
Private lMsErroAuto := .F.
 
aAdd(aSA1Auto,{"A1_END"     ,ODADOSEND[1] ,Nil}) 
aAdd(aSA1Auto,{"A1_BAIRRO"  ,ODADOSEND[3] ,Nil}) 
aAdd(aSA1Auto,{"A1_EST"     ,ODADOSEND[5] ,Nil}) 
aAdd(aSA1Auto,{"A1_MUN"     ,ODADOSEND[4] ,Nil}) 
aAdd(aSA1Auto,{"A1_COMPLEM" ,ODADOSEND[2] ,Nil}) 

// Exec auto do CRMA980 (Antigo MATA030)	
MSExecAuto({|a,b,c| CRMA980(a,b,c)}, aSA1Auto, nOpcAuto, aAI0Auto)
	
If lMsErroAuto  
	lRet := lMsErroAuto
Else
	MSGINFO("Endereço atualizado com sucesso!")
	oDlgCEP:End()
EndIf
     
Return lRet
